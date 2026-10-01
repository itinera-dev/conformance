# Itinera conformance suite

Test cases, written as data, that every [Itinera](https://github.com/itinera-dev/spec) implementation must pass.

## Status

Not started. The case format will be defined together with version 0.1 of the specification.

## How it will work

- Each case contains a workflow, scripted step outcomes and the expected trace, and cites the accepted proposal and the section of the specification it checks.
- The expected trace is the stream of events the engine emits, recorded by a reporter.
- Cases are tagged with their tier. A language claims a tier only when every case of that tier and the tiers before it passes.
- Each language implements a small runner that loads the cases, runs them and produces a report.

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
