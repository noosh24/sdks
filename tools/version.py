import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SOURCES = {
    "php": [("php/src/Client.php", r"const VERSION = '([^']+)'")],
    "node": [("node/package.json", r'"version": "([^"]+)"'), ("node/src/version.ts", r"VERSION = '([^']+)'")],
    "python": [("python/src/noosh24/_version.py", r'__version__ = "([^"]+)"')],
    "dotnet": [
        ("dotnet/src/Noosh24.OpenApi/Noosh24.OpenApi.csproj", r"<Version>([^<]+)</Version>"),
        ("dotnet/src/Noosh24.OpenApi/Noosh24Client.cs", r'const string Version = "([^"]+)"'),
    ],
    "java": [
        ("java/gradle.properties", r"^version=(\S+)"),
        ("java/src/main/java/com/noosh24/openapi/Noosh24Client.java", r'VERSION = "([^"]+)"'),
    ],
    "go": [("go/client.go", r'Version\s+= "([^"]+)"')],
    "ruby": [("ruby/lib/noosh24/version.rb", r'VERSION = "([^"]+)"')],
    "dart": [("dart/pubspec.yaml", r"^version: (\S+)"), ("dart/lib/src/version.dart", r"packageVersion = '([^']+)'")],
    "rust": [("rust/Cargo.toml", r'^version = "([^"]+)"')],
    "cpp": [
        ("cpp/CMakeLists.txt", r"VERSION (\d+\.\d+\.\d+)"),
        ("cpp/vcpkg.json", r'"version": "([^"]+)"'),
        ("cpp/conanfile.py", r'version = "([^"]+)"'),
        ("cpp/include/noosh24/version.hpp", r'version = "([^"]+)"'),
    ],
    "swift": [("swift/Sources/Noosh24/Noosh24Client.swift", r'static let version = "([^"]+)"')],
}


def versions(lang):
    found = {}
    for path, pattern in SOURCES[lang]:
        with open(os.path.join(ROOT, path)) as f:
            match = re.search(pattern, f.read(), flags=re.M)
        if not match:
            raise SystemExit("%s: no version found with %s" % (path, pattern))
        found[path] = match.group(1)
    return found


def set_version(lang, version):
    if not re.fullmatch(r"\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?", version):
        raise SystemExit("%s is not a semantic version" % version)
    for path, pattern in SOURCES[lang]:
        full = os.path.join(ROOT, path)
        with open(full) as f:
            text = f.read()
        match = re.search(pattern, text, flags=re.M)
        if not match:
            raise SystemExit("%s: no version found with %s" % (path, pattern))
        text = text[: match.start(1)] + version + text[match.end(1):]
        with open(full, "w") as f:
            f.write(text)
        print("%s -> %s" % (path, version))


def main(argv):
    if not argv or argv[0] not in SOURCES:
        raise SystemExit("usage: version.py <%s> [expected | --set <version>]" % "|".join(SOURCES))
    if len(argv) == 3 and argv[1] == "--set":
        set_version(argv[0], argv[2])
        return
    found = versions(argv[0])
    distinct = set(found.values())
    if len(distinct) != 1:
        raise SystemExit("versions disagree: " + ", ".join("%s=%s" % kv for kv in found.items()))
    version = distinct.pop()
    if len(argv) > 1 and argv[1] != version:
        raise SystemExit("tag says %s but %s declares %s" % (argv[1], argv[0], version))
    print(version)


if __name__ == "__main__":
    main(sys.argv[1:])
