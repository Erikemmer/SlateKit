# SlateKit – common tasks. `make help` lists them.
.DEFAULT_GOAL := help

# Where SwiftPM puts build products. The repo lives in a synced folder
# (`~/Documents`), and the sync attaches Finder metadata to freshly built files,
# which makes codesign refuse the test bundle ("resource fork, Finder
# information, or similar detritus not allowed"). Building outside the synced
# folder avoids it. Override with `make test SCRATCH=.build`.
SCRATCH ?= $(HOME)/Library/Caches/SlateKit/build

.PHONY: help test build lint format clean

test: ## Run the unit tests
	swift test --scratch-path $(SCRATCH)

build: ## Build the package
	swift build --scratch-path $(SCRATCH)

lint: ## Check formatting with swift-format (ships with the Swift 6 toolchain)
	swift format lint --recursive --strict Sources Tests

format: ## Reformat sources in place
	swift format --in-place --recursive Sources Tests

clean: ## Remove build products
	rm -rf .build $(SCRATCH)

help: ## List the targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
