import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import MODELS, ROOT, parse, snake  # noqa: E402


def read(fname, kind):
    key = 'data["%s"]' % fname
    if kind == "s":
        return "Convert.str(%s)" % key
    if kind == "i":
        return "Convert.int(%s)" % key
    if kind == "f":
        return "Convert.float(%s)" % key
    if kind == "b":
        return "Convert.bool(%s)" % key
    if kind == "t":
        return "Convert.time(%s)" % key
    if kind == "[s]":
        return "Convert.strings(%s)" % key
    if kind == "{f}":
        return "Convert.floats(%s)" % key
    if kind.startswith("["):
        return "Convert.list_of(%s, %s)" % (key, kind[1:-1])
    if kind.startswith("{"):
        return "Convert.map_of(%s, %s)" % (key, kind[1:-1])
    return "Convert.object(%s, %s)" % (key, kind)


def model(name, spec):
    fields = parse(spec)
    lines = ["  %s = Data.define(" % name]
    for i, (fname, _, _, _) in enumerate(fields):
        lines.append("    :%s%s" % (snake(fname), "," if i < len(fields) - 1 else ""))
    lines += [
        "  ) do",
        "    include Model",
        "",
        "    def self.from_hash(data)",
        "      data = Convert.mapping(data)",
        "      new(",
    ]
    for fname, kind, _, _ in fields:
        lines.append("        %s: %s," % (snake(fname), read(fname, kind)))
    lines += [
        "        raw: data",
        "      )",
        "    end",
        "  end",
    ]
    return lines


def gen():
    lines = ["# frozen_string_literal: true", "", "module Noosh24"]
    for i, (name, _, spec) in enumerate(MODELS):
        if i:
            lines.append("")
        lines += model(name, spec)
    lines += ["end", ""]
    path = os.path.join(ROOT, "ruby", "lib", "noosh24", "models.rb")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    gen()
