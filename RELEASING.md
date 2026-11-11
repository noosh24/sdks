# Releasing

Every SDK is released on its own, from a tag named `<folder>/v<version>`: `php/v0.1.0`, `node/v0.2.0`, `rust/v1.0.0-beta.1`.

## Cut a release

```bash
python3 tools/version.py node --set 0.2.0
git commit -am "release: Node.js SDK 0.2.0"
git tag node/v0.2.0
git push origin main node/v0.2.0
```

`tools/version.py <folder> --set <version>` writes the version into every file that carries it (package manifest and the version constant the client sends in its User-Agent). `tools/version.py <folder>` prints it and fails if the files disagree.

The tag starts [`.github/workflows/release.yml`](.github/workflows/release.yml):

1. **Check.** The version in the tag must match the files, or nothing is released.
2. **Test and build.** The SDK's tests run again and its package is built.
3. **GitHub Release.** A release named after the SDK and version is created with the commits that touched the folder since its previous tag, and the built package attached (`.tgz`, wheel and sdist, `.nupkg`, `.jar`, `.gem`, `.crate`, source tarball). A version with a `-` suffix is marked as a pre-release.
4. **Registry.** The package is published, but only when the registry is switched on (below).

Every SDK also lives in its own read-only repository, `noosh24/noosh24-<folder>`: [`split.yml`](.github/workflows/split.yml) pushes the folder there on every push to `main` and turns `<folder>/vX.Y.Z` into a plain `vX.Y.Z` tag. PHP, Go and Swift have no upload step, because Packagist, the Go proxy and SwiftPM read those repositories.

### Releases in the per-language repositories

After the release here, the `mirror` job creates the same release in `noosh24/noosh24-<folder>`, so every SDK's own repository shows its releases. The workflow's own token cannot write to other repositories, so this uses a fine-grained personal access token stored as the repository secret `MIRROR_RELEASE_TOKEN`:

- Resource owner: `noosh24`
- Repository access: the `noosh24-*` repositories
- Permissions: Contents → Read and write (Metadata read-only is added automatically)

Without the secret the job only warns and the mirror gets the tag without a release.

## Switching a registry on

Publishing uses short-lived OIDC tokens from GitHub ("trusted publishing") wherever the registry supports it, so no long-lived registry token is stored in the repository. Each registry needs a one-time setup by an owner of the Noosh24 account there; after that, set the repository variable in **Settings → Secrets and variables → Actions → Variables**.

Every trusted-publisher form asks for the same values:

| Field | Value |
| --- | --- |
| Owner / organisation | `noosh24` |
| Repository | `sdks` |
| Workflow file | `release.yml` |
| Environment | `release` |

| SDK | Registry | One-time setup | Variable |
| --- | --- | --- | --- |
| Node.js | npm | Create the `noosh24` organisation on npmjs.com. Publish 0.1.0 once by hand (`npm publish --access public` from `node/`) so the package exists, then add a trusted publisher in the package settings. | `PUBLISH_NPM=true` |
| Python | PyPI | Add a "pending publisher" for project `noosh24` at pypi.org/manage/account/publishing. | `PUBLISH_PYPI=true` |
| C# / .NET | NuGet | Reserve the `Noosh24` prefix, add a trusted publishing policy at nuget.org (Account → Trusted publishing). | `PUBLISH_NUGET=true`, `NUGET_USER=<nuget.org user>` |
| Ruby | RubyGems | Add a pending trusted publisher for gem `noosh24` at rubygems.org/profile/oidc/pending_trusted_publishers. MFA must be on. | `PUBLISH_RUBYGEMS=true` |
| Dart | pub.dev | Create a verified publisher for noosh24.com. Publish 0.1.0 once by hand (`dart pub publish` from `dart/`), then on the package admin page enable "Automated publishing" from GitHub Actions with repository `noosh24/sdks`, tag pattern `dart/v{{version}}` and environment `release`. | `PUBLISH_PUB=true` |
| Rust | crates.io | Publish 0.1.0 once by hand (`cargo publish` from `rust/`), then add a trusted publisher in the crate settings. | `PUBLISH_CRATES=true` |
| Java | Maven Central | Verify the `com.noosh24` namespace at central.sonatype.com (a DNS TXT record on noosh24.com), generate a user token, and create a GPG key whose public half is on keys.openpgp.org. Store `CENTRAL_USERNAME`, `CENTRAL_PASSWORD`, `SIGNING_KEY` (ASCII-armoured private key) and `SIGNING_PASSWORD` as secrets of the `release` environment. | `PUBLISH_MAVEN=true` |
| PHP | Packagist | Submit `https://github.com/noosh24/noosh24-php` at packagist.org/packages/submit under a `noosh24` account and enable the GitHub hook. | none |
| Go | Go proxy | Nothing: `split.yml` asks proxy.golang.org for the new version after tagging. pkg.go.dev picks it up from there. | none |
| Swift | Swift Package Index | Optional: add `https://github.com/noosh24/noosh24-swift` at swiftpackageindex.com/add-a-package. | none |
| C++ | none yet | The release carries a source tarball; consumers use CMake `FetchContent` or the bundled `vcpkg.json`/`conanfile.py`. | none |

The `release` environment only accepts tags matching `*/v*`; add required reviewers to it if a person should approve every publish.

## Before 1.0

All SDKs start at 0.1.0. Until 1.0.0 a minor version may change the public API; patch versions do not.
