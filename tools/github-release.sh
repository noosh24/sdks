#!/usr/bin/env bash
set -euo pipefail

tag="$1"
title="$2"
shift 2
prefix="${tag%%/*}"
repo="${GITHUB_REPOSITORY:-noosh24/sdks}"

prev="$(git tag --list "$prefix/v*" --sort=-v:refname | grep -v -x -F "$tag" | head -n 1 || true)"
range="$tag"
if [ -n "$prev" ]; then
  range="$prev..$tag"
fi

notes="$(mktemp)"
{
  echo "## Changes"
  echo
  git log --no-merges --format='- %s (%h)' "$range" -- "$prefix" .github/workflows/release.yml
  echo
  echo "Install and usage: [${prefix}/README.md](https://github.com/$repo/tree/$tag/$prefix#install)"
  if [ -n "$prev" ]; then
    echo
    echo "**Full diff:** https://github.com/$repo/compare/$prev...$tag"
  fi
} > "$notes"

flags=()
case "$tag" in
  *-*) flags+=(--prerelease) ;;
esac

if gh release view "$tag" --repo "$repo" > /dev/null 2>&1; then
  gh release edit "$tag" --repo "$repo" --title "$title" --notes-file "$notes"
else
  gh release create "$tag" --repo "$repo" --verify-tag --title "$title" --notes-file "$notes" ${flags[@]+"${flags[@]}"}
fi

if [ "$#" -gt 0 ]; then
  gh release upload "$tag" --repo "$repo" --clobber "$@"
fi
