# Releasing Rampart

Releases are automated with [Release Please](https://github.com/googleapis/release-please).
**Cutting a release = merging the open `release: vX.Y.Z` pull request.** Nothing else.

---

## How it works

1. Every pull request is squash-merged, so its **title becomes the commit
   message on `main`**. Titles follow [Conventional Commits](https://www.conventionalcommits.org/)
   (enforced by the `pr-title` check):

   | Title prefix | Release notes section | Version bump (0.x) |
   | :--- | :--- | :--- |
   | `security:` | 🔒 Security | patch |
   | `feat:` | ✨ Features | minor |
   | `fix:` | 🐞 Bug Fixes | patch |
   | `perf:` | ⚡ Performance | patch |
   | `deps:` | 📦 Dependencies | patch |
   | `revert:` | ⏪ Reverts | patch |
   | `docs:` | 📝 Documentation | patch |
   | `refactor:` `test:` `ci:` `build:` `chore:` `style:` | hidden | — |
   | any type with `!` (e.g. `feat(api)!:`) or a `BREAKING CHANGE:` footer | ⚠ BREAKING CHANGES | minor (while < 1.0) |

   A scope is optional: `fix(notifier): …`.

2. On every push to `main`, the `release-please` workflow updates one open
   pull request titled `release: vX.Y.Z`. It contains:
   - the next version, computed from the titles above;
   - the new `CHANGELOG.md` section, grouped by the sections above with a link to each PR;
   - the version bump in `backend/Cargo.toml` (workspace), `backend/Cargo.lock`
     (workspace crates), `frontend/package.json`, `frontend/package-lock.json`,
     `version.txt` and `.release-please-manifest.json`.

3. **Merge the release PR** (squash) when you want to ship. The workflow then:
   - tags the merge commit `vX.Y.Z` and publishes the GitHub release with the
     new CHANGELOG section as its notes;
   - builds the binaries (Linux x86_64 / aarch64, macOS x86_64 / aarch64) and
     attaches them with SHA-256 sums, signed build-provenance attestations and
     an SPDX SBOM;
   - publishes the multi-arch image to `ghcr.io/<owner>/rampart` as `X.Y.Z`,
     `X.Y` and `latest`, signed with cosign (keyless) and carrying provenance
     and SBOM attestations;
   - publishes the Helm chart to `oci://ghcr.io/<owner>/charts`;
   - appends a 🙌 Contributors section (with first-time contributors) to the
     release notes.

The version lives in `[workspace.package].version` in `backend/Cargo.toml` and
reaches the binary through `env!("CARGO_PKG_VERSION")` (`/healthz`, `/metrics`,
the dashboard header). Never bump it by hand; Release Please does.

---

## Upgrade notes

When a release needs operator action (a behaviour change, a manual migration
step), say so in the PR that introduces it:

- mark it breaking (`feat(x)!:` or a `BREAKING CHANGE: <what to do>` footer in
  the squash commit body); the text appears under ⚠ BREAKING CHANGES, or
- after the release is published, add an **Upgrade notes** paragraph at the top
  of the GitHub release (the release body is editable), and if needed the same
  paragraph to its `CHANGELOG.md` section in a follow-up `docs:` PR.

---

## Choosing the version

Release Please picks the version from the titles (table above). To override it,
merge a PR into `main` whose squash commit body ends with this footer (for
example an empty `chore: release 0.160.0` commit); the release PR updates to
that version:

```
Release-As: 0.160.0
```

---

## Verifying a release

```bash
# Binary provenance
gh attestation verify rampart-x86_64-unknown-linux-gnu -R <owner>/rampart

# Image provenance + signature
gh attestation verify oci://ghcr.io/<owner>/rampart:X.Y.Z -R <owner>/rampart
cosign verify ghcr.io/<owner>/rampart:X.Y.Z \
  --certificate-identity-regexp 'https://github.com/<owner>/rampart/.github/workflows/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# Version baked into the binary
curl -s http://localhost:3000/healthz   # {"status":"alive","version":"X.Y.Z"}
```

---

## Fixing a release

- **A build job failed:** fix forward on `main`, then rebuild the assets for the
  existing tag with *Actions → release → Run workflow* (input: the tag). Don't
  move or delete published tags.
- **A bad release shipped:** merge the fix with a `fix:` title; the next release
  PR picks it up. Mark the broken release's notes on GitHub if users must skip it.

---

## Tokens

The workflow works with the default `GITHUB_TOKEN`. With it, the release PR
gets no CI run, because GitHub doesn't trigger workflows from changes made with
that token. That's acceptable: the release PR only changes version metadata.
To have CI run on release PRs too, add a repository secret
`RELEASE_PLEASE_TOKEN` (a GitHub App or fine-grained token with
`contents: write` and `pull-requests: write`); the workflow uses it when present.
