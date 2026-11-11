#!/bin/bash
# Update brew formulae/casks and mise tools.
#
# DELIBERATELY no `brew cu` and no `--greedy`: they reinstall microsoft-office via the
# full .pkg, which resets Outlook and wipes all accounts/signatures. Microsoft Office
# updates come from Microsoft AutoUpdate only. See docs/MIGRATION.md.
set -euo pipefail

brew update
brew upgrade
brew cleanup
mise upgrade
