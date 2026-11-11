import os
import re
import sys
from urllib.parse import quote

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = "https://github.com/noosh24/sdks"
RAW = "https://raw.githubusercontent.com/noosh24/sdks/main"
SITE = "https://developer.noosh24.com"
BRAND = "DC4A38"

LANGS = [
    {
        "dir": "php", "name": "PHP", "title": "PHP", "package": "noosh24/open-api", "registry": "Packagist",
        "runtime": ("PHP", "8.2+", "777BB4", "php"), "fence": "bash", "install": "composer require noosh24/open-api",
    },
    {
        "dir": "node", "name": "Node.js / TypeScript", "title": "Node.js and TypeScript", "package": "@noosh24/open-api",
        "registry": "npm", "runtime": ("Node.js", "22+", "5FA04E", "nodedotjs"), "fence": "bash",
        "install": "npm install @noosh24/open-api",
    },
    {
        "dir": "python", "name": "Python", "title": "Python", "package": "noosh24", "registry": "PyPI",
        "runtime": ("Python", "3.11+", "3776AB", "python"), "fence": "bash", "install": "pip install noosh24",
    },
    {
        "dir": "dotnet", "name": "C# / .NET", "title": "C# and .NET", "package": "Noosh24.OpenApi", "registry": "NuGet",
        "runtime": (".NET", "10+", "512BD4", "dotnet"), "fence": "bash", "install": "dotnet add package Noosh24.OpenApi",
    },
    {
        "dir": "java", "name": "Java / Kotlin", "title": "Java and Kotlin", "package": "com.noosh24:noosh24-open-api",
        "registry": "Maven Central", "runtime": ("Java", "21+", "ED8B00", "openjdk"), "fence": "kotlin",
        "install": 'implementation("com.noosh24:noosh24-open-api:0.1.0")',
    },
    {
        "dir": "go", "name": "Go", "title": "Go", "package": "github.com/noosh24/noosh24-go", "registry": "Go modules",
        "runtime": ("Go", "1.26+", "00ADD8", "go"), "fence": "bash", "install": "go get github.com/noosh24/noosh24-go",
    },
    {
        "dir": "rust", "name": "Rust", "title": "Rust", "package": "noosh24", "registry": "crates.io",
        "runtime": ("Rust", "stable", "000000", "rust"), "fence": "bash", "install": "cargo add noosh24",
    },
    {
        "dir": "cpp", "name": "C++", "title": "C++", "package": "noosh24", "registry": "CMake",
        "runtime": ("C++", "20", "00599C", "cplusplus"), "fence": "cmake",
        "install": "FetchContent_Declare(noosh24 GIT_REPOSITORY https://github.com/noosh24/sdks.git GIT_TAG cpp/v0.1.0 SOURCE_SUBDIR cpp)",
    },
    {
        "dir": "ruby", "name": "Ruby", "title": "Ruby", "package": "noosh24", "registry": "RubyGems",
        "runtime": ("Ruby", "3.3+", "CC342D", "ruby"), "fence": "bash", "install": "gem install noosh24",
    },
    {
        "dir": "dart", "name": "Dart", "title": "Dart", "package": "noosh24", "registry": "pub.dev",
        "runtime": ("Dart", "3.11+", "0175C2", "dart"), "fence": "bash", "install": "dart pub add noosh24", "server_only": True,
    },
    {
        "dir": "swift", "name": "Swift", "title": "Swift", "package": "Noosh24", "registry": "SwiftPM",
        "runtime": ("Swift", "6", "F05138", "swift"), "fence": "swift",
        "install": '.package(url: "https://github.com/noosh24/noosh24-swift.git", from: "0.1.0")', "server_only": True,
    },
]

INTRO = (
    "Menu, reservations, orders and bills, payments and the Z-report, tables, customers, loyalty, stock and reviews "
    "of a Noosh24 venue, plus creating and cancelling reservations."
)


def shield(label, message, color, logo=None):
    url = "https://img.shields.io/badge/%s-%s-%s" % (
        quote(label.replace("-", "--"), safe=""),
        quote(message.replace("-", "--"), safe=""),
        color,
    )
    if logo:
        url += "?logo=%s&logoColor=white" % logo
    return url


def badges(lang):
    label, version, color, logo = lang["runtime"]
    ci = "%s/actions/workflows/%s.yml" % (REPO, lang["dir"])
    return " ".join(
        [
            '<a href="%s"><img src="%s/badge.svg" alt="CI"></a>' % (ci, ci),
            '<img src="%s" alt="%s %s">' % (shield(label, version, color, logo), label, version),
            '<img src="%s" alt="%s">' % (shield(lang["registry"], lang["package"], BRAND), lang["registry"]),
            '<a href="%s/blob/main/LICENSE"><img src="%s" alt="MIT license"></a>' % (REPO, shield("license", "MIT", "blue")),
        ]
    )


def anchor(heading):
    text = heading.strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def callout(lang):
    if lang.get("server_only"):
        return (
            "> [!CAUTION]\n"
            "> **Server-side only.** A Noosh24 API key opens the venue's whole account: guests' phone numbers, "
            "payments, and writing reservations. Never ship it inside a mobile, desktop or web app that leaves your "
            "hands, because it can be pulled out of the bundle. Let the app call your own backend, and use this SDK there.\n"
        )
    return (
        "> [!IMPORTANT]\n"
        "> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, "
        "payments, and writing reservations. Never put it in a browser, a mobile app or a public repository.\n"
    )


def logo(width):
    return '<a href="%s"><img src="%s/.github/assets/noosh-lockup.svg" alt="Noosh24" width="%d"></a>' % (SITE, RAW, width)


def header(lang):
    return "\n".join(
        [
            '<div align="center">',
            "",
            logo(260),
            "",
            "# Noosh24 Open API for %s" % lang["title"],
            "",
            "**The official %s client for the [Noosh24 Open API](%s).**<br>" % (lang["title"], SITE),
            INTRO,
            "",
            badges(lang),
            "",
            "[Developer site](%s) · [API reference](%s/reference) · [All SDKs](%s) · [Report an issue](%s/issues)"
            % (SITE, SITE, REPO, REPO),
            "",
            "</div>",
            "",
        ]
    )


def split(md):
    if md.startswith('<div align="center">'):
        start = md.index("\n## Requirements\n")
        after = md[start + len("\n## Requirements\n"):]
        nxt = after.index("\n## ")
        bullets = [line for line in after[:nxt].splitlines() if line.startswith("- ")]
        return bullets, after[nxt + 1:]
    first = md.index("\n## ")
    prefix, rest = md[:first], md[first + 1:]
    bullets = [line for line in prefix.splitlines() if line.startswith("- ")]
    return bullets, rest


def restyle(lang):
    path = os.path.join(ROOT, lang["dir"], "README.md")
    if not os.path.exists(path):
        return False
    with open(path) as f:
        md = f.read()
    md = re.sub(r"\n## Security: server-side only\n.*?\n---\n", "\n", md, flags=re.S)
    bullets, rest = split(md)
    bullets = [b for b in bullets if "API reference:" not in b]
    headings = ["Requirements"] + re.findall(r"^## (.+)$", rest, flags=re.M)
    contents = " · ".join("[%s](#%s)" % (h, anchor(h)) for h in headings)
    out = header(lang) + "\n" + callout(lang) + "\n" + "**Contents:** " + contents + "\n\n## Requirements\n\n"
    out += "\n".join(bullets) + "\n\n" + rest
    with open(path, "w") as f:
        f.write(out)
    return True


def quick_start(lang):
    path = os.path.join(ROOT, lang["dir"], "README.md")
    with open(path) as f:
        md = f.read()
    section = md.split("\n## Quick start\n", 1)[1]
    block = re.search(r"```(\w+)\n(.*?)\n```", section, flags=re.S)
    return block.group(1), block.group(2)


def root(done):
    rows = []
    for lang in done:
        label, version, _, _ = lang["runtime"]
        rows.append(
            "| [%s](%s) | `%s` | %s | %s %s | [![CI](%s/actions/workflows/%s.yml/badge.svg)](%s/actions/workflows/%s.yml) |"
            % (lang["name"], lang["dir"], lang["package"], lang["registry"], label, version, REPO, lang["dir"], REPO, lang["dir"])
        )
    details = []
    for lang in done:
        fence, code = quick_start(lang)
        details.append(
            "<details>\n<summary><b>%s</b> · <code>%s</code></summary>\n\n```%s\n%s\n```\n\n```%s\n%s\n```\n\nMore in the [%s README](%s/README.md).\n\n</details>"
            % (lang["name"], lang["install"], lang["fence"], lang["install"], fence, code, lang["name"], lang["dir"])
        )
    names = ", ".join(lang["name"] for lang in done)
    out = "\n".join(
        [
            '<div align="center">',
            "",
            logo(360),
            "",
            "# Noosh24 Open API SDKs",
            "",
            "**Official clients for the [Noosh24 Open API](%s).**<br>" % SITE,
            "Connect delivery aggregators, accounting, loyalty, digital signage and BI to a Noosh24 restaurant in a few lines.",
            "",
            '<img src="%s" alt="API 1.1.0"> <img src="%s" alt="%d languages"> <a href="LICENSE"><img src="%s" alt="MIT license"></a>'
            % (shield("Open API", "1.1.0", BRAND), shield("SDKs", "%d languages" % len(done), "555555"), len(done), shield("license", "MIT", "blue")),
            "",
            "[Developer site](%s) · [API reference](%s/reference) · [OpenAPI spec](spec/openapi.json) · [Report an issue](%s/issues)" % (SITE, SITE, REPO),
            "",
            "</div>",
            "",
            "## Languages",
            "",
            "| Language | Package | Registry | Runtime | Tests |",
            "| --- | --- | --- | --- | --- |",
            *rows,
            "",
            "## Quick start",
            "",
            "Get an API key for your venue from Noosh24, put it in `NOOSH24_API_KEY`, and pick your language:",
            "",
            *details,
            "",
            "> [!IMPORTANT]",
            "> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository. Mobile and web apps call your own backend, and your backend uses an SDK.",
            "",
            "## What every SDK gives you",
            "",
            "- **One client, one key.** Build it with the venue's API key; an optional base URL, timeout, retry count and user agent. `whoami` shows the venue, the key's scopes and the venue's modules.",
            "- **Every resource.** `menu`, `reservations`, `orders` and bills, `payments` and the Z-report, `tables` and halls, `customers`, `loyalty`, `stock` and `reviews`, named after the API's tags.",
            "- **Typed models.** Every response is a typed object in the language's own style, with timestamps as native date-times and money in AZN.",
            "- **Lists that page themselves.** `limit`, `offset`, `sort`, `where` and `expand` on every list, a page with `total` and `hasMore`, and an iterator that walks every page on demand.",
            "- **A safe `where` builder.** AND-only conditions with strings, dates and numbers quoted the way the API expects (`'Chef''s'`).",
            "- **Idempotent reservations.** `create` with your own `externalRef` returns the existing booking on a repeat instead of making a second one, and tells you which it was. `cancel` is safe to repeat.",
            "- **Typed errors.** One error type per API code, under status-level parents, so code can catch `TableTaken` or every `PermissionDenied` at once.",
            "- **Retries done right.** `429`, `502`, `503`, `504` and network errors are retried with `Retry-After` or exponential backoff, never more than 60 seconds, and never for a create without an `externalRef`.",
            "",
            "## Errors",
            "",
            "| HTTP | `error` | Meaning |",
            "| --- | --- | --- |",
            "| 400 | `validation_error` | A parameter is wrong, for example a field that cannot be filtered. |",
            "| 401 | `no_api_key`, `invalid_api_key` | No key, or a wrong or revoked one. |",
            "| 403 | `insufficient_scope` | The key lacks the scope the endpoint needs. |",
            "| 403 | `module_not_enabled` | The venue does not have the loyalty or inventory module. |",
            "| 403 | `venue_suspended` | The venue is suspended. |",
            "| 403 | `not_your_reservation` | The booking was not made through this API. |",
            "| 404 | `not_found`, `table_not_found` | No such row in this venue. |",
            "| 409 | `table_taken` | The table is already held for that time. |",
            "| 409 | `cannot_cancel` | The guest is seated or the booking is over. |",
            "| 422 | `outside_hours`, `in_the_past`, `table_too_small` | The booking cannot be made as asked. |",
            "| 429 | `rate_limit_exceeded` | Too many requests: 600 a minute per key. Wait `Retry-After` seconds. |",
            "| 503 | `temporarily_unavailable` | Try again. |",
            "",
            "## Repository layout",
            "",
            "```text",
            *["%-10s %s SDK" % (lang["dir"] + "/", lang["name"]) for lang in done],
            "spec/      openapi.json the SDKs are built against (API 1.1.0)",
            "tools/     model generators and this README generator",
            "```",
            "",
            "The models in every SDK come from one table in `tools/gen_models.py` and a generator per language (`tools/gen_<lang>.py`). After a spec change, update the table and regenerate. These READMEs are kept in one style by `python3 tools/readme.py`.",
            "",
            "## Versioning and releases",
            "",
            "Each SDK has its own version and its own tag, `<folder>/v<version>` (for example `php/v0.1.0`). PHP, Go and Swift are mirrored to [noosh24-php](https://github.com/noosh24/noosh24-php), [noosh24-go](https://github.com/noosh24/noosh24-go) and [noosh24-swift](https://github.com/noosh24/noosh24-swift), because Packagist, Go modules and SwiftPM read a package from the repository root; open issues and pull requests here. [RELEASING.md](RELEASING.md) has the steps and the one-time registry setup.",
            "",
            "Every SDK supports the runtime versions its upstream still maintains and is tested on the oldest and the newest of them.",
            "",
            "## Contributing",
            "",
            "Issues and pull requests are welcome. Each SDK's README ends with a Development section that shows how to run its tests; CI runs them on every supported runtime.",
            "",
            "## License",
            "",
            "[MIT](LICENSE) © Noosh24",
            "",
        ]
    )
    with open(os.path.join(ROOT, "README.md"), "w") as f:
        f.write(out)
    return names


if __name__ == "__main__":
    only = set(sys.argv[1:])
    done = [lang for lang in LANGS if (not only or lang["dir"] in only) and restyle(lang)]
    print("restyled:", root([lang for lang in LANGS if os.path.exists(os.path.join(ROOT, lang["dir"], "README.md"))]) if not only else ", ".join(lang["dir"] for lang in done))
