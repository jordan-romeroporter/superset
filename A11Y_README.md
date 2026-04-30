# Accessibility Devin Action — Testing Guide

This repo includes a GitHub Action (`.github/workflows/a11y-devin.yml`) that automatically triages WCAG 2.1 AA violations on PRs that touch `.tsx`, `.jsx`, or `.html` files. Below is how to test it.

## Automatic (via GitHub Actions)

Open or push to any PR that modifies `.tsx`, `.jsx`, or `.html` files. The action triggers automatically, and Devin will:

1. Audit the diff for WCAG 2.1 AA violations
2. Post inline `suggestion` blocks with one-click fixes
3. File Linear tickets for tracking

No setup needed beyond the repo secrets (`DEVIN_API_KEY`, `DEVIN_ORG_ID`) which are already configured.

## Local Simulation

To simulate the workflow against any open PR without waiting for CI:

```bash
# Required env vars (export or add to .env)
export DEVIN_API_KEY=...   # from https://app.devin.ai/settings
export DEVIN_ORG_ID=...    # your Devin org ID
export GITHUB_TOKEN=...    # GitHub PAT with repo scope

./scripts/simulate-a11y.sh <owner/repo> <pr_number>
```

Example:

```bash
./scripts/simulate-a11y.sh jordan-romeroporter/superset 5
```

The script fetches the PR diff, filters for front-end files, builds the prompt from `prompts/devin-a11y-session.md`, creates a Devin session, and polls until completion.

### Dry-Run

Inspect the fully-rendered prompt without calling the Devin API:

```bash
DRY_RUN=1 ./scripts/simulate-a11y.sh jordan-romeroporter/superset 5
```
