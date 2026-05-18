#!/usr/bin/env bash
set -euo pipefail

fallback_major=1
fallback_minor=0
fallback_patch=0

git_output() {
  git "$@" 2>/dev/null || true
}

is_semver_tag() {
  [[ "$1" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
}

latest_semver_tag() {
  local tag
  while IFS= read -r tag; do
    if is_semver_tag "$tag"; then
      printf '%s\n' "$tag"
      return 0
    fi
  done < <(git_output tag --merged HEAD --sort=-v:refname)
  return 1
}

emit() {
  local key="$1"
  local value="$2"
  printf '%s=%s\n' "$key" "$value"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >> "$GITHUB_OUTPUT"
  fi
}

anchor_tag="$(latest_semver_tag || true)"
major="$fallback_major"
minor="$fallback_minor"
patch="$fallback_patch"

if [[ -n "$anchor_tag" && "$anchor_tag" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
fi

short_sha="$(git_output rev-parse --short HEAD)"
if [[ -z "$short_sha" ]]; then
  short_sha="unknown"
fi

total_commit_count="$(git_output rev-list --count HEAD)"
if ! [[ "$total_commit_count" =~ ^[0-9]+$ ]] || (( total_commit_count < 1 )); then
  total_commit_count=1
fi

if [[ -n "$anchor_tag" ]]; then
  relative_commit_count="$(git_output rev-list --count "$anchor_tag..HEAD")"
else
  relative_commit_count="$total_commit_count"
fi

if ! [[ "$relative_commit_count" =~ ^[0-9]+$ ]]; then
  relative_commit_count=0
fi

if [[ -n "$anchor_tag" && "$relative_commit_count" == "0" ]]; then
  marketing_version="$major.$minor.$patch"
  artifact_version="$marketing_version"
else
  next_patch=$((patch + 1))
  marketing_version="$major.$minor.$next_patch"
  artifact_version="$marketing_version+$relative_commit_count.g$short_sha"
fi

artifact_slug="${artifact_version//+/-}"

emit "marketing_version" "$marketing_version"
emit "build_version" "$total_commit_count"
emit "artifact_version" "$artifact_version"
emit "artifact_slug" "$artifact_slug"
emit "anchor_tag" "$anchor_tag"
emit "relative_commit_count" "$relative_commit_count"
emit "short_sha" "$short_sha"
