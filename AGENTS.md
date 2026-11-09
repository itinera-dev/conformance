# AGENTS.md: working in itinera-dev/conformance

The manual for anyone, human or agent, writing or changing conformance cases. The rules of the specification repository's [AGENTS.md](https://github.com/itinera-dev/spec/blob/main/AGENTS.md) apply here too; this file adds what is specific to cases.

## What to read

- [FORMAT.md](FORMAT.md): how a case is written, its tags and its tables.
- [STEPS.md](STEPS.md): the catalogue. A case may use only its sentences.

## Writing cases

1. **Repetition is a signal.** When a scenario repeats a sentence with only its arguments changing, such as several `defines the hook` lines, judge whether a table or a list sentence would say it better. If so, add that sentence to STEPS.md, defined in terms of the existing ones, and use it. Keep the single sentence where it occurs once or twice.
2. **Repeated scenarios are a signal too.** When every scenario of a feature opens with the same steps, judge whether a `Background` would say them once; when a feature checks several rules, judge whether a `Rule` for each, with its scenarios under it, would make the feature easier to follow. Weigh this against reading each scenario on its own: a `Background` is worth it only when the steps it holds are the same in every scenario and say something about the feature, not when they are only the usual one-step workflow.
3. **Frozen tiers stay as they are.** Implementations pin a released version, and a tier released in a version is frozen. Change its cases only when a later proposal changes the behaviour they check, never only to shorten them.
