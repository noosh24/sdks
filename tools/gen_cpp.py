import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
gen_models = importlib.import_module("gen_models")
MODELS = gen_models.MODELS
parse = gen_models.parse
snake = gen_models.snake

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

KEYWORDS = {
    "alignas", "alignof", "and", "asm", "auto", "bool", "break", "case", "catch", "char", "class", "concept",
    "const", "consteval", "constexpr", "constinit", "continue", "default", "delete", "do", "double", "else",
    "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int",
    "long", "mutable", "namespace", "new", "noexcept", "not", "nullptr", "operator", "or", "private",
    "protected", "public", "register", "requires", "return", "short", "signed", "sizeof", "static", "struct",
    "switch", "template", "this", "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned",
    "using", "virtual", "void", "volatile", "while", "xor",
}


def member(name):
    out = snake(name)
    return out + "_" if out in KEYWORDS else out


def cpp_type(kind):
    if kind == "s":
        return "std::optional<std::string>"
    if kind == "i":
        return "std::optional<std::int64_t>"
    if kind == "f":
        return "std::optional<double>"
    if kind == "b":
        return "std::optional<bool>"
    if kind == "t":
        return "std::optional<Timestamp>"
    if kind == "[s]":
        return "std::vector<std::string>"
    if kind == "{f}":
        return "std::map<std::string, double>"
    if kind.startswith("["):
        return "std::vector<%s>" % kind[1:-1]
    if kind.startswith("{"):
        return "std::map<std::string, %s>" % kind[1:-1]
    return "std::optional<%s>" % kind


def cpp_read(fname, kind):
    key = '"%s"' % fname
    if kind == "s":
        return "detail::read_string(data, %s)" % key
    if kind == "i":
        return "detail::read_int(data, %s)" % key
    if kind == "f":
        return "detail::read_double(data, %s)" % key
    if kind == "b":
        return "detail::read_bool(data, %s)" % key
    if kind == "t":
        return "detail::read_timestamp(data, %s)" % key
    if kind == "[s]":
        return "detail::read_strings(data, %s)" % key
    if kind == "{f}":
        return "detail::read_doubles(data, %s)" % key
    if kind.startswith("["):
        return "detail::read_list<%s>(data, %s)" % (kind[1:-1], key)
    if kind.startswith("{"):
        return "detail::read_map<%s>(data, %s)" % (kind[1:-1], key)
    return "detail::read_object<%s>(data, %s)" % (kind, key)


def header():
    lines = [
        "#pragma once",
        "",
        "#include <cstdint>",
        "#include <map>",
        "#include <optional>",
        "#include <string>",
        "#include <vector>",
        "",
        "#include <nlohmann/json.hpp>",
        "",
        "#include <noosh24/time.hpp>",
        "",
        "namespace noosh24 {",
        "",
    ]
    for name, _, spec in MODELS:
        lines.append("struct %s {" % name)
        for fname, kind, _, _ in parse(spec):
            lines.append("    %s %s;" % (cpp_type(kind), member(fname)))
        lines.append("    nlohmann::json raw;")
        lines.append("")
        lines.append("    [[nodiscard]] static %s from_json(const nlohmann::json& data);" % name)
        lines.append("};")
        lines.append("")
    lines.append("using ZReport = nlohmann::json;")
    lines.append("")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def source():
    lines = [
        '#include "noosh24/models.hpp"',
        "",
        '#include "internal.hpp"',
        "",
        "namespace noosh24 {",
        "",
    ]
    for name, _, spec in MODELS:
        lines.append("%s %s::from_json(const nlohmann::json& data)" % (name, name))
        lines.append("{")
        lines.append("    %s out;" % name)
        for fname, kind, _, _ in parse(spec):
            lines.append("    out.%s = %s;" % (member(fname), cpp_read(fname, kind)))
        lines.append("    out.raw = data;")
        lines.append("    return out;")
        lines.append("}")
        lines.append("")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def write(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(text)


if __name__ == "__main__":
    write("cpp/include/noosh24/models.hpp", header())
    write("cpp/src/models.cpp", source())
