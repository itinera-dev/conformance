# Itinera conformance suite

Test cases, written as data, that every [Itinera](https://github.com/itinera-dev/spec) implementation must pass.

## Status

Every case of tier 1, specification 0.1.0, is here. Until a first implementation passes them all, they are released as candidates, `v0.1.0-rc.N`; then they are tagged `v0.1.0`, like the specification.

## How it works

- **The cases** are Gherkin features under [cases/](cases/), one folder per proposal: `cases/tier-N/NNNN-short-name/`. Each scenario builds a workflow, scripts what its steps and hooks do, and checks the result and the event stream.
- **The format** is in [FORMAT.md](FORMAT.md): tags, values and types, event tables, versions, and how a language runs the cases through its `conformance.json` manifest.
- **The sentences** a case may use form a closed catalogue, [STEPS.md](STEPS.md). Each language implements every sentence once, in its runner.
- **Tags** give each case's tier, proposal and required capabilities. A language claims a tier only when every case of that tier and the tiers before it passes.
- **Each language** implements a small runner that loads the cases, runs them and produces a report.

The process is described in [PROCESS.md](https://github.com/itinera-dev/spec/blob/main/PROCESS.md).

Built with AI under the terms of [A manifesto for software engineering with AI](https://marlon-sousa.com/blog/manifesto/); see [how Itinera is built](https://github.com/itinera-dev/.github/blob/main/CONTRIBUTING.md#how-itinera-is-built).

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
