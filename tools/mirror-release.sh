#!/usr/bin/env bash
set -euo pipefail

tag="$1"
mirror="$2"
title="$3"
source_repo="${GITHUB_REPOSITORY:-noosh24/sdks}"
version_tag="${tag#*/}"

for _ in $(seq 1 30); do
  if gh api "repos/$mirror/git/ref/tags/$version_tag" > /dev/null 2>&1; then
    break
  fi
  sleep 10
done

notes="$(mktemp)"
{
  gh release view "$tag" --repo "$source_repo" --json body --jq .body
  echo
  echo "Developed in [$source_repo](https://github.com/$source_repo) ([$tag](https://github.com/$source_repo/releases/tag/$tag)); this repository is a read-only mirror."
} > "$notes"

flags=()
case "$version_tag" in
  *-*) flags+=(--prerelease) ;;
esac

if gh release view "$version_tag" --repo "$mirror" > /dev/null 2>&1; then
  gh release edit "$version_tag" --repo "$mirror" --title "$title" --notes-file "$notes"
else
  gh release create "$version_tag" --repo "$mirror" --verify-tag --title "$title" --notes-file "$notes" ${flags[@]+"${flags[@]}"}
fi

assets="$(mktemp -d)"
gh release download "$tag" --repo "$source_repo" --dir "$assets" 2> /dev/null || true
if [ -n "$(ls -A "$assets")" ]; then
  gh release upload "$version_tag" --repo "$mirror" --clobber "$assets"/*
fi
