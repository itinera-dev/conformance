# Conformance case format

Conformance cases are written in Gherkin, as `.feature` files, and run by Cucumber in each language: cucumber-rs for Rust, cucumber-js for TypeScript, Cucumber-JVM for Kotlin and Java. Each language implements the step definitions once; the cases are shared by every language.

This document is the contract for writing cases. The sentences a case may use are listed in [STEPS.md](STEPS.md).

## Status

Draft, agreed in [#5](https://github.com/itinera-dev/conformance/issues/5). The format is finalised together with version 0.1 of the specification.

## Rules

1. **Only catalogued sentences.** Every `Given`, `When`, `Then`, `And` and `But` line uses a sentence from [STEPS.md](STEPS.md), with its parameters. A sentence outside the catalogue is an error, not an extension. A new sentence is added to the catalogue in the same pull request as the first case that needs it, with its exact meaning.
2. **Scripted steps, not business steps.** The steps of a workflow under test are test steps whose behaviour the scenario dictates: what they request, what they contribute, and how each attempt ends. The same holds for policies and adapters.
3. **The trace is the event stream.** Behaviour is checked by comparing the events the engine emitted, recorded by a reporter, with a table. Other `Then` sentences check the journey's result, which is also observable. A workflow refused before any journey exists has no event stream: its trace is the refusal, the error listing every violation that building the workflow (through the language's builder, while the runner runs) or admitting it returns, and the runner checks that error directly.
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

A scenario added to settle a spec defect also carries `@spec-defect-NNNN`, the number of the defect issue in `spec`, so the correction can be traced. It lives with the cases of the proposal whose text it clarifies.

A feature or scenario that needs a capability also carries:

- `@capability-sync` or `@capability-async`: the execution mode it requires;
- a tag for a rule a language may make impossible to express (proposal 0054): `@invalid-lifecycle`, `@role-not-provided`, `@mode-not-accepted`, `@non-value` or `@late-handle`;
- other capability tags as later tiers add them.

A language runs the cases of the proposals it lists in its manifest (see below), excluding capabilities it does not claim, and every one must pass. It claims tier N of a specification version once every proposal of tiers 1 to N is listed.

## Values and types

- **Keys** are strings, written in double quotes.
- **Values** are written as JSON: `"text"`, `42`, `4.5`, `true`, `null`, `[1, 2]`, `{"a": 1}`.
- **Types** use this neutral vocabulary: `string`, `integer`, `number`, `boolean`, `list`, `object`. A language maps each to its own types in its step definitions.
- **Numbers.** A JSON number written without a fraction or an exponent, such as `42`, is an `integer`. Any other JSON number, such as `4.5` or `4.0`, is a `number`.
- **Cases MUST NOT depend on whether an `integer` is also a `number`.** No case requests `number` for an integer value, or `integer` for a non-integer value, and expects either success or `wrong type`: languages differ on it. A wrong-type scenario uses types that differ in every language, such as `string` against `integer`.

## Events

Event tables use one row per event. The column `event` is required; any of these columns may be added, and **an empty cell is not compared**:

- `step`, `attempt`: the step and attempt the event concerns;
- `key`: the data key it concerns;
- `code`: the reason code it carries, for events about a failure, a skip or an abort;
- `retriable`: `true` or `false`, for `step_failed`;
- `policy`, `hook`, `lifecycle`: for events from or about a hook; `lifecycle` is the lifecycle returned, or `none`;
- `adapter`: the input adapter an event names;
- `source`: who made a contribution: the step's name, or the policy and hook as `policy, hook`;
- `cause`: the cause carried by a decision event, such as `retries exhausted`;
- `decided by`: who took a decision: `default`, or the policy and hook as `policy, hook`;
- `message`, `data`: for events emitted by steps and hooks; `data` is JSON.

Two sentences compare them:

- "the events include, in order" checks that these events appear in this order, possibly with others in between;
- "the events are exactly" checks the complete stream.

Event names are those of the engine catalogue of proposal 0011 (Events), as amended by proposal 0040, and the `step_*` and `journey_*` events steps and hooks emit.

## Versions of the cases

This repository is tagged with the specification's versions, in three parts, for example `v0.1.0`. The cases at a tag never change, and a tag is never moved.

- **Release candidates.** Until a version is proven by a first implementation passing all its cases, each change to the cases is released as a new candidate: `v0.1.0-rc.1`, `v0.1.0-rc.2`, and so on. Implementations pin the latest candidate.
- **Proven.** The version is then tagged `v0.1.0`, here and in the specification.
- **Afterwards.** Corrections of spec defects are released as patch versions, such as `v0.1.1`, and accepted proposals as minor versions, such as `v0.2.0`. See "The behaviour specification" in the specification's [PROCESS.md](https://github.com/itinera-dev/spec/blob/main/PROCESS.md).

## Running the cases in a language

Each language repository runs the cases as its conformance tests.

1. **A manifest**, `conformance.json` at the root of the language repository, states:
   - `cases`: the tag of this repository it runs against, for example `v0.1.0`;
   - `proposals`: the numbers of the proposals it implements, for example `[2, 8]`. A proposal is listed by the pull request that completes it, which also closes the language's implementation issue for it; from then on its cases run on every pull request. The tier the language claims follows from this list;
   - `capabilities`: the capabilities it claims, for example `["sync", "async"]`;
   - `impossible`: the rules the language makes impossible to express (proposal 0054), as a map from each excluded tag to the scenarios it excludes, each with the test in the language's own suite that proves the rule cannot be expressed:

     ```json
     "impossible": {
       "invalid-lifecycle": [
         {
           "feature": "cases/tier-1/0010-hooks-lifecycles-and-roles/order-and-lifecycles.feature",
           "scenario": "A lifecycle a hook may not return aborts the journey",
           "proof": { "test": "success_hook_cannot_return_retry", "file": "tests/compile_fail/lifecycle.rs" }
         }
       ]
     }
     ```

     Every scenario carrying an excluded tag at the pinned `cases` tag MUST have an entry, and every entry MUST name a scenario that exists there. The language's own CI runs the proving tests.
2. **A runner** in the language repository holds the step definitions for every sentence in [STEPS.md](STEPS.md) and runs the cases with that language's Cucumber implementation. The runner builds each scenario's workflow programmatically, while the program runs, from the scenario's sentences and tables, using the language's public API for constructing workflows; scripted test steps declare their inputs, contributions and outcomes the same way. How a language's own declarative syntax, such as annotations or macros, maps onto that API is tested in the language's own test suite, not here. It is started by one command, documented in the language repository, and:
   - reads the cases from the directory named by the environment variable `ITINERA_CONFORMANCE_CASES`;
   - runs only the scenarios selected by the Cucumber tag expression in `ITINERA_CONFORMANCE_TAGS`;
   - writes a Cucumber JSON report to the file named by `ITINERA_CONFORMANCE_REPORT`, holding only the scenarios that ran;
   - exits with a failure when any selected scenario fails.
3. **The recorder.** The runner gives the executor a dispatcher factory whose dispatchers hold its recording reporter, from which every `Then` sentence about events reads (proposal 0063). When a scenario says the executor uses its default dispatcher, the runner gives no factory, and the scenario's sentences read the reporters the workflow lists.
4. **The `run-conformance` action** from [itinera-dev/actions](https://github.com/itinera-dev/actions) reads the manifest, downloads the cases at the pinned tag, builds the tag expression (the listed proposals, without capabilities the language does not claim and without its `impossible` tags), sets the three variables and runs the language's command. Before running, it fails if a scenario carrying an excluded tag has no entry in `impossible`, or if an entry names a scenario that does not exist at the pinned tag.
5. **The report** is the Cucumber JSON and, next to it, an exclusions file the action writes from the manifest: for every excluded scenario, its feature, its name, its tag and its proof. The runner never writes it. Together they are the conformance report a release carries, and the compatibility table reads both, so it tells a scenario excluded with proof from one that was skipped or never run.

## When the cases run

- **On every pull request** in a language repository, as a required check, for the proposals already listed. A pull request that breaks a finished proposal cannot be merged, while work on a proposal not yet listed merges freely.
- **Moving to newer cases** is a pull request that changes `cases` in the manifest. Until a language passes the newer cases, only that pull request is affected.
- **On every release** of a language, as a gate: if any case fails, there is no release. A release that passes carries its conformance report as a release asset, which is the proof of what it claims.

## The compatibility table

This repository publishes a compatibility table on its GitHub Pages site: for every released version of every language, the cases version, the tiers and capabilities claimed, and the scenarios passed for each proposal. A workflow here rebuilds it from the languages' releases and their attached reports, on a daily schedule and on demand, and publishes it to Pages without changing this repository's `main` branch.
