# Security scanning

The same scanners run locally as git hooks (`.pre-commit-config.yaml`) and in CI
(`.github/workflows/security.yml`), so `git commit --no-verify` is not a bypass.

| Tool | Catches | Local hook | CI |
|------|---------|-----------|----|
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secrets by pattern: staged diff, commit message, full history | commit, commit-msg, pre-push | `secrets` job (full history) |
| [TruffleHog](https://github.com/trufflesecurity/trufflehog) | Verified (live) credentials | commit | — |
| [zizmor](https://docs.zizmor.sh) | GitHub Actions security: unpinned actions, credential persistence, template injection, broad permissions, dangerous triggers, Dependabot cooldown | commit (when `.github/` changes) | `workflows` job, incl. online audits (impostor commits, known-vulnerable actions) |
| [actionlint](https://github.com/rhysd/actionlint) | Workflow syntax and expression errors | commit (when workflows change) | `workflows` job |
| [Trivy](https://trivy.dev) `config` | Misconfiguration in Dockerfiles, Helm chart, Kubernetes manifests | — | `trivy` job |
| pre-commit-hooks | Private keys, AWS credentials, large files, merge markers, YAML/JSON/TOML syntax | commit | — |
| `cargo deny` | Rust advisories, licences, sources | — | `security-audit` workflow |
| CodeQL | Code-level vulnerabilities (Rust, JS/TS, Actions) | — | `codeql` workflow |

Each CI check also writes its output to the run's **Summary** page
(`scripts/ci-summary.sh`).

## Setup (once per clone)

```bash
brew install pre-commit gitleaks actionlint   # trufflehog, zizmor, shellcheck are fetched by pre-commit
pre-commit install                            # installs pre-commit, commit-msg and pre-push hooks
pre-commit run --all-files                    # check everything once
```

## Pinning

Every third-party action is pinned to a full commit SHA, and every CI container
image to a digest, so nobody can swap the code behind a tag. That is how the
March 2026 `aquasecurity/trivy-action` compromise (CVE-2026-33634) stole
credentials; Trivy therefore runs from a digest-pinned image, not that action.

After adding or bumping an action or a `*_IMAGE` in a workflow:

```bash
brew install pinact
GITHUB_TOKEN=$(gh auth token) scripts/pin-ci.sh
```

Dependabot keeps the pins current (with a 7-day cooldown so fresh releases age
before we adopt them). Pre-commit hook revisions are frozen to SHAs too; update
them with `pre-commit autoupdate --freeze`.

## False positives

- **gitleaks:** add a narrow allowlist to `.gitleaks.toml`, scoped to one rule
  *and* one path. Never allowlist a whole directory for every rule.
- **zizmor:** fix the finding where possible. If a finding is intentional, add
  `# zizmor: ignore[<audit>]` on the flagged line with a comment saying why
  (see `conflict-labeler.yml` and `release-please.yml`).

If a real secret is ever committed, treat it as leaked: rotate it first, then
clean history. Removing the commit alone is not enough.
