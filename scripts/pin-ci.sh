#!/bin/sh
# Pin everything CI runs, so nobody can swap the code behind a version tag
# (that is how the March 2026 trivy-action attack worked):
#   1. every `uses: owner/action@vX` -> the release's full commit SHA (+ "# vX.Y.Z" comment), via pinact
#   2. every `*_IMAGE: ghcr.io/...:tag` env value -> `:tag@sha256:<digest>`
# Run on the Mac/ROG after changing a workflow or bumping a version. Needs: pinact, curl.
#   brew install pinact
set -eu
cd "$(dirname "$0")/.."
command -v pinact >/dev/null || { echo "pinact missing: brew install pinact" >&2; exit 1; }

pinact run   # pins all workflows under .github/workflows

for f in .github/workflows/*.yml; do
  grep -E '^  [A-Z_]+_IMAGE: ghcr\.io/' "$f" | while IFS= read -r line; do
    var=$(echo "$line" | sed -E 's/^  ([A-Z_]+_IMAGE):.*/\1/')
    ref=$(echo "$line" | sed -E 's/^  [A-Z_]+_IMAGE: ([^ #]+).*/\1/')
    ref=${ref%@*}                              # drop an old digest
    repo=${ref#ghcr.io/}; repo=${repo%:*}; tag=${ref##*:}
    token=$(curl -fsS "https://ghcr.io/token?scope=repository:${repo}:pull" | sed -E 's/.*"token":"([^"]+)".*/\1/')
    digest=$(curl -fsSI -H "Authorization: Bearer ${token}" \
      -H "Accept: application/vnd.oci.image.index.v1+json" \
      -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" \
      "https://ghcr.io/v2/${repo}/manifests/${tag}" | tr -d '\r' | grep -i '^docker-content-digest:' | awk '{print $2}')
    case "$digest" in sha256:*) ;; *) echo "no digest for ${ref}" >&2; exit 1;; esac
    sed -i.bak -E "s|^  ${var}: .*|  ${var}: ghcr.io/${repo}:${tag}@${digest} # pinned by scripts/pin-ci.sh|" "$f" && rm -f "$f.bak"
    echo "pinned ${var} -> ${tag}@${digest}"
  done
done
echo "done; check with: zizmor .github/workflows && actionlint"
