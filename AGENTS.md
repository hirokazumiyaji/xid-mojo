# Repository Guidelines

## Project Structure

This repository is a Mojo package for generating and parsing XIDs. Library code lives in `src/xid/`: `id.mojo` defines the ID representation and encoding, `generator.mojo` creates IDs, and `system.mojo` handles host and process information. Tests are standalone Mojo programs under `tests/`; `consumer.mojo` checks package precompilation and use from outside the source tree. The English and Japanese READMEs document usage. Pixi configuration and the Conda recipe are in `pixi.toml` and `conda.recipe/`.

## Build, Test, and Development

Use the locked Pixi environment for a consistent Mojo toolchain:

- `pixi install` installs dependencies from `pixi.lock`.
- `pixi run format` formats `src` and `tests` with `mojo format`.
- `pixi run test` runs all ID, system, and generator test programs.
- `pixi run test-id`, `pixi run test-system`, or `pixi run test-generator` runs one suite.
- `pixi run test-consumer` precompiles the package and checks it through the consumer program.

CI checks formatting, runs the test suites, and checks the consumer program on Linux and macOS. Format changes before committing and ensure they leave no diff.

## Coding Style

Write Mojo using the conventions already present in `src/xid/` and `tests/`. Use `snake_case` for functions and variables, and descriptive names for public APIs. Keep changes focused and prefer straightforward implementations. Do not add explanatory comments; comments should record intent or rationale that is not clear from the code. Run `pixi run format` after editing Mojo files.

## Testing

Tests are plain `.mojo` programs, not a separate test framework. Add or update a focused test in the matching `tests/*_test.mojo` file for behavior changes, and use `pixi run test` to run all suites. Changes affecting package imports or compilation should also run `pixi run test-consumer`.

## Commits and Pull Requests

Recent history uses short conventional prefixes such as `feat:`, `fix:`, `style:`, and `refactor:`; keep commit subjects concise and action-oriented. Pull requests should explain the behavior change, note relevant tests and formatting checks, and link related issues when applicable. Include examples or output when they clarify a user-visible API change.

## Security

XIDs are not secrets. Preserve the README guidance: do not use generated IDs as passwords, tokens, session secrets, or other security-sensitive identifiers.
