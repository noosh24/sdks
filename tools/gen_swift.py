import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import ENUMS, MODELS, parse, write  # noqa: E402

OUT = "swift/Sources/Noosh24"

CASE_NAMES = {"none": "noSubscription"}


def camel(value):
    parts = [p for p in re.split(r"[_\-]", value) if p]
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def enum_name(model, fname):
    return model + fname[0].upper() + fname[1:]


def case_name(value):
    return CASE_NAMES.get(value, camel(value))


def swift_type(model, fname, kind):
    if (model, fname) in ENUMS:
        return enum_name(model, fname)
    if kind == "s":
        return "String"
    if kind == "i":
        return "Int"
    if kind == "f":
        return "Double"
    if kind == "b":
        return "Bool"
    if kind == "t":
        return "Date"
    if kind.startswith("["):
        return "[%s]" % swift_type(model, None, kind[1:-1])
    if kind.startswith("{"):
        return "[String: %s]" % swift_type(model, None, kind[1:-1])
    return kind


def element_type(model, kind):
    return swift_type(model, None, kind[1:-1])


def read(model, fname, kind):
    if kind == "t":
        return "c.lenientDate(forKey: .%s)" % fname
    if kind.startswith("["):
        return "c.lenientList(%s.self, forKey: .%s)" % (element_type(model, kind), fname)
    if kind.startswith("{"):
        return "c.lenientMap(%s.self, forKey: .%s)" % (element_type(model, kind), fname)
    return "c.lenient(%s.self, forKey: .%s)" % (swift_type(model, fname, kind), fname)


def gen_models():
    lines = ["import Foundation", ""]
    for name, _, spec in MODELS:
        fields = parse(spec)
        lines.append("public struct %s: Noosh24Model {" % name)
        for fname, kind, _, _ in fields:
            lines.append("    public let %s: %s?" % (fname, swift_type(name, fname, kind)))
        lines.append("    public let raw: JSONValue?")
        lines.append("")
        params = ", ".join("%s: %s? = nil" % (f, swift_type(name, f, k)) for f, k, _, _ in fields)
        lines.append("    public init(%s, raw: JSONValue? = nil) {" % params)
        for fname, _, _, _ in fields:
            lines.append("        self.%s = %s" % (fname, fname))
        lines.append("        self.raw = raw")
        lines.append("    }")
        lines.append("")
        lines.append("    enum CodingKeys: String, CodingKey {")
        lines.append("        case %s" % ", ".join(f for f, _, _, _ in fields))
        lines.append("    }")
        lines.append("")
        lines.append("    public init(from decoder: any Decoder) throws {")
        lines.append("        let c = try decoder.container(keyedBy: CodingKeys.self)")
        for fname, kind, _, _ in fields:
            lines.append("        %s = %s" % (fname, read(name, fname, kind)))
        lines.append("        raw = try? JSONValue(from: decoder)")
        lines.append("    }")
        lines.append("")
        lines.append("    public func encode(to encoder: any Encoder) throws {")
        lines.append("        var c = encoder.container(keyedBy: CodingKeys.self)")
        for fname, _, _, _ in fields:
            lines.append("        try c.encodeIfPresent(%s, forKey: .%s)" % (fname, fname))
        lines.append("    }")
        lines.append("}")
        lines.append("")
    lines.append("public typealias ZReport = [String: JSONValue]")
    lines.append("")
    write(OUT + "/Models.swift", "\n".join(lines))


def gen_enums():
    lines = []
    for (model, fname), values in ENUMS.items():
        name = enum_name(model, fname)
        lines.append("public enum %s: Hashable, Sendable, Codable, RawRepresentable, CaseIterable {" % name)
        for value in values:
            lines.append("    case %s" % case_name(value))
        lines.append("    case unknown(String)")
        lines.append("")
        lines.append("    public static let allCases: [%s] = [%s]" % (name, ", ".join("." + case_name(v) for v in values)))
        lines.append("")
        lines.append("    public init(rawValue: String) {")
        lines.append("        switch rawValue {")
        for value in values:
            lines.append('        case "%s": self = .%s' % (value, case_name(value)))
        lines.append("        default: self = .unknown(rawValue)")
        lines.append("        }")
        lines.append("    }")
        lines.append("")
        lines.append("    public var rawValue: String {")
        lines.append("        switch self {")
        for value in values:
            lines.append('        case .%s: "%s"' % (case_name(value), value))
        lines.append("        case .unknown(let value): value")
        lines.append("        }")
        lines.append("    }")
        lines.append("}")
        lines.append("")
    write(OUT + "/Enums.swift", "\n".join(lines))


if __name__ == "__main__":
    gen_models()
    gen_enums()
