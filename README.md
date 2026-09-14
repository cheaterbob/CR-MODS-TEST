# Captivity Reloaded temporary mod catalog

This repository is a disposable integration fixture for Captivity Reloaded's in-game GitHub mod browser.
It is not the final community catalog.

The root `catalog-v1.json` is fetched by the game. Test packs live under `packs/`. Canonical ZIP files
live under `release-assets/` and are attached to versioned `test-v*` GitHub Releases automatically.
They are committed deliberately so GitHub uploads the exact bytes whose SHA-256 values appear in the catalog.
Run `scripts/build-release-assets.ps1` and commit the resulting archives whenever a source fixture changes.

Current fixtures:

- **Catalog Test Difficulty** adds a clearly named difficulty option.
- **Catalog Sprint Mode** adds a clearly named game-mode option.
- **Dependent Catalog Mode** requires Catalog Dependency Support and tests automatic batch installation.
- **Catalog Dependency Support** is a dedicated missing-dependency fixture fetched with the latest Dependent Catalog Mode.

Both use unique pack IDs so they can be installed through Browse without colliding with the examples
already shipped in a development checkout.
