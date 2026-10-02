# Conformance case format

Conformance cases are written in Gherkin, as `.feature` files, and run by Cucumber in each language: cucumber-rs for Rust, cucumber-js for TypeScript, Cucumber-JVM for Kotlin and Java. Each language implements the step definitions once; the cases are shared by every language.

This document is the contract for writing cases. The sentences a case may use are listed in [STEPS.md](STEPS.md).

## Status

Draft, agreed in [#5](https://github.com/itinera-dev/conformance/issues/5). The format is finalised together with version 0.1 of the specification.

## Rules

1. **Only catalogued sentences.** Every `Given`, `When`, `Then`, `And` and `But` line uses a sentence from [STEPS.md](STEPS.md), with its parameters. A sentence outside the catalogue is an error, not an extension. A new sentence is added to the catalogue in the same pull request as the first case that needs it, with its exact meaning.
2. **Scripted steps, not business steps.** The steps of a workflow under test are test steps whose behaviour the scenario dictates: what they request, what they contribute, and how each attempt ends. The same holds for policies and adapters.
3. **The trace is the event stream.** Behaviour is checked by comparing the events the engine emitted, recorded by a reporter, with a table. Other `Then` sentences check the journey's result, which is also observable.
4. **One behaviour per scenario.** A scenario checks one rule of the specification. Its name states the rule in plain words.
5. **Cite the source.** The feature's description names the proposal and, once it exists, the section of the specification it checks.
6. **Screen-reader friendly.** Plain sentences and simple tables. No ASCII art, no decorative characters.

## Layout

- `cases/tier-N/NNNN-short-name/` holds the cases of one proposal, where `NNNN` is the proposal's number.
- One `.feature` file per topic of the proposal, named after the topic, for example `data-from-the-workflow.feature`.

## Tags

Every feature carries:

- `@tier-N`: the tier it belongs to;
- `@proposal-NNNN`: the proposal it checks.

A feature or scenario that needs a capability also carries:

- `@capability-sync` or `@capability-async`: the execution mode it requires;
- other capability tags as later tiers add them.

A language runs the cases of the proposals it lists in its manifest (see below), excluding capabilities it does not claim, and every one must pass. It claims tier N of a specification version once every proposal of tiers 1 to N is listed.

## Values and types

- **Keys** are strings, written in double quotes.
- **Values** are written as JSON: `"text"`, `42`, `4.5`, `true`, `null`, `[1, 2]`, `{"a": 1}`.
- **Types** use this neutral vocabulary: `string`, `integer`, `number`, `boolean`, `list`, `object`. A language maps each to its own types in its step definitions.

## Events

Event tables use one row per event and these columns, leaving a cell empty when it does not apply:

- `event`: the event's name in the engine event catalogue;
- `step`: the step it concerns;
- `key`: the data key it concerns;
- `attempt`: the attempt number;
- `code`: the reason code it carries, for events about a failure or a skip.

Two sentences compare them:

- "the events include, in order" checks that these events appear in this order, possibly with others in between;
- "the events are exactly" checks the complete stream.

Event names follow the engine event catalogue defined by the events proposal ([itinera-dev/spec#11](https://github.com/itinera-dev/spec/issues/11)). Until it is accepted, names in the cases are provisional and will be aligned with it.

## Versions of the cases

This repository is versioned with tags aligned with the specification's versions, for example `v0.1.0`. The cases at a tag never change. Fixes and new cases are released under a new tag.

## Running the cases in a language

Each language repository runs the cases as its conformance tests.

1. **A manifest**, `conformance.json` at the root of the language repository, states:
   - `cases`: the tag of this repository it runs against, for example `v0.1.0`;
   - `proposals`: the numbers of the proposals it implements, for example `[2, 8]`. A proposal is listed by the pull request that completes it, which also closes the language's implementation issue for it; from then on its cases run on every pull request. The tier the language claims follows from this list;
   - `capabilities`: the capabilities it claims, for example `["sync", "async"]`.
2. **A runner** in the language repository holds the step definitions for every sentence in [STEPS.md](STEPS.md) and runs the cases with that language's Cucumber implementation. The runner builds each scenario's workflow programmatically, while the program runs, from the scenario's sentences and tables, using the language's public API for constructing workflows; scripted test steps declare their inputs, contributions and outcomes the same way. How a language's own declarative syntax, such as annotations or macros, maps onto that API is tested in the language's own test suite, not here. It is started by one command, documented in the language repository, and:
   - reads the cases from the directory named by the environment variable `ITINERA_CONFORMANCE_CASES`;
   - runs only the scenarios selected by the Cucumber tag expression in `ITINERA_CONFORMANCE_TAGS`;
   - writes a Cucumber JSON report to the file named by `ITINERA_CONFORMANCE_REPORT`;
   - exits with a failure when any selected scenario fails.
3. **The `run-conformance` action** from [itinera-dev/actions](https://github.com/itinera-dev/actions) reads the manifest, downloads the cases at the pinned tag, builds the tag expression (the listed proposals, without capabilities the language does not claim), sets the three variables and runs the language's command.

## When the cases run

- **On every pull request** in a language repository, as a required check, for the proposals already listed. A pull request that breaks a finished proposal cannot be merged, while work on a proposal not yet listed merges freely.
- **Moving to newer cases** is a pull request that changes `cases` in the manifest. Until a language passes the newer cases, only that pull request is affected.
- **On every release** of a language, as a gate: if any case fails, there is no release. A release that passes carries its conformance report as a release asset, which is the proof of what it claims.

## The compatibility table

This repository publishes a compatibility table on its GitHub Pages site: for every released version of every language, the cases version, the tiers and capabilities claimed, and the scenarios passed for each proposal. A workflow here rebuilds it from the languages' releases and their attached reports, on a daily schedule and on demand, and publishes it to Pages without changing this repository's `main` branch.
