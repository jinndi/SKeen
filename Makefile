.PHONY: build build-skeen build-api

# Build all release artifacts under dist/.
build: build-skeen build-api

# Requires Go and shfmt.
build-skeen:
	sh .github/build-shell-scripts.sh dist

# Installs dashboard dependencies when needed, then builds dist/skeen-api.
build-api: dashboard/node_modules
	npm --prefix dashboard run build:api

dashboard/node_modules: dashboard/package.json dashboard/package-lock.json
	npm ci --prefix dashboard
