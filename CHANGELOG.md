# Changelog

## Unreleased

- DSL: Rename external variables API to `add_variables/5` (formerly temporary `variables/5`).
  - Keep `variables/5` as deprecated wrapper for back-compat in experimental tests.
  - No change to in-block DSL: `variables/4` remains the canonical form inside `Problem.define/modify`.
- Tests: Update experimental generator syntax and integration tests to use `add_variables/5` and correct interpolated constraint names.

## v0.2 - First version that downloads the HiGHS binary at compile-time

We now download the HiGHS binary at compile time.
Not all architectures are supported yet.
Documentation is still lacking, especially regarding configuration options.

## v0.1 - First public version

Most of the functionality is already implemented.
When dependent packages become stable, the version will be upgraded to 1.0.
