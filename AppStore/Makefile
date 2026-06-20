# Baby Light — localization & release pipeline.
# Single source of truth: i18n/locales.json + i18n/source.json + i18n/translations/.
# Run from the AppStore/ directory:  make help

PY := python3
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
LOCALES ?=

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

validate: ## Check every locale for completeness + Apple char limits
	@$(PY) i18n/lib.py

catalogs: ## Generate the iOS + watch String Catalogs (.xcstrings)
	@$(PY) i18n/build_catalogs.py

screenshots: ## Render localized screenshots (LOCALES="de-DE fr-FR" for a subset)
	@$(PY) i18n/screenshots.py $(LOCALES)

all: validate catalogs screenshots ## validate + catalogs + screenshots

add-locale: ## Add a language: make add-locale ASC=sv XCODE=sv SCRIPT=latin NAME=Swedish
	@test -n "$(ASC)" && test -n "$(XCODE)" && test -n "$(SCRIPT)" && test -n "$(NAME)" \
	  || (echo "usage: make add-locale ASC=.. XCODE=.. SCRIPT=.. NAME=.."; exit 1)
	@$(PY) i18n/scaffold_locale.py "$(ASC)" "$(XCODE)" "$(SCRIPT)" "$(NAME)"

build: ## Build the current branch via Xcode Cloud (App Store workflow)
	@$(PY) asc/xcode_cloud.py build-for "$(BRANCH)"

build-testflight: ## Build the current branch via Xcode Cloud (TestFlight internal)
	@$(PY) asc/xcode_cloud.py build-for "$(BRANCH)" --testflight

stage: ## Stage the next App Store version (after the current one is released)
	@$(PY) asc/stage_v11.py

submit: ## Stage AND submit the next version for review
	@$(PY) asc/stage_v11.py --submit

.PHONY: help validate catalogs screenshots all add-locale build build-testflight stage submit
