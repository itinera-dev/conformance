# Step catalogue

The only sentences a conformance case may use, with their exact meaning. Rules for using them are in [FORMAT.md](FORMAT.md). In the sentences, `<name>` is a parameter: a quoted string for names and keys, a JSON value for values, a type from the neutral vocabulary for types.

Each sentence names the proposal that introduced it.

## Building a workflow

- **`Given a workflow "<workflow>" with the steps:`** followed by a table with the column `step`, one row per step in declaration order. Declares a workflow whose steps are scripted test steps. (0002)
- **`And step "<step>" requests input "<key>" of type <type>`**: the step declares a required input. (0002)
- **`And step "<step>" requests optional input "<key>" of type <type>`**: the step declares an optional input. (0002)
- **`And step "<step>" contributes "<key>" = <value>`**: when the step runs, it contributes this key and value before ending. (0002)
- **`And step "<step>" succeeds`**: every attempt of the step ends with success. (0002)

## Data

- **`And the data bag is empty`**: the journey starts with no initial data. (0002)
- **`And the data bag contains:`** followed by a table with the columns `key` and `value`: the journey starts with this data. (0002)

## Input adapters

- **`And the workflow declares an input adapter for step "<step>" and key "<key>" that returns <value>`** (0002)
- **`And the workflow declares an input adapter for step "<step>" and key "<key>" that has no value`**: the adapter reports that it has no value. (0002)
- **`And the workflow declares an input adapter for step "<step>" and key "<key>" that fails with "<message>"`**: the adapter fails, in whatever way the language expresses failure. (0002)

## Policies

- **`And a step policy "<policy>" defines the hook "<hook>"`**: a step policy whose hook does nothing beyond what other sentences add, and returns no lifecycle. (0002)
- **`And a workflow policy "<policy>" defines the hook "<hook>"`** (0002)
- **`And step "<step>" has the policies "<policy>", "<policy>"`**: attaches step policies, in this order. One or more names. (0002)
- **`And the workflow has the policies "<policy>", "<policy>"`**: attaches workflow policies, in this order. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests step data "<key>" of type <type>`**: a required request for data from the step. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests optional step data "<key>" of type <type>`** (0002)
- **`And the hook "<hook>" of policy "<policy>" requests the step name`**: the hook asks for the name of the step it is acting on. (0002)

## Actions

- **`When the workflow is admitted`**: admission only; nothing runs. (0002)
- **`When the workflow runs`**: admission, then the journey. (0002)
- **`When the workflow is listed`**: the workflow's declaration is read without running anything. (0002)

## Outcomes

- **`Then admission is refused with the violations:`** followed by a table with the column `violation`, using the violation names below. The order of rows does not matter. (0002)
- **`Then no step ran`** (0002)
- **`Then the journey succeeded`** (0002)
- **`Then the journey was aborted`** (0002)
- **`Then step "<step>" was built with input "<key>" = <value>`** (0002)
- **`Then step "<step>" was built with input "<key>" absent`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" = <value>`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" absent`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received the step name "<step>"`**: on at least one call, the hook received this step name. (0002)
- **`Then the listing is:`** followed by a table with the columns `step`, `position`, `policies` and `adapters`, where `policies` lists the attached policies' names and `adapters` lists the keys that have an input adapter, each separated by commas in declaration order, and empty when there are none. (0002)

## Events

- **`Then the events include, in order:`** followed by an event table. (0002)
- **`Then the events are exactly:`** followed by an event table. (0002)

## Hook names

Until the hooks proposal ([itinera-dev/spec#10](https://github.com/itinera-dev/spec/issues/10)) is accepted, cases use these provisional names: `on step success`, `on step failure`, `on step retry`, `on step abnormal termination`, `on workflow success`, `on workflow failure`. (0002)

## Violation names

- **`hook defined twice`**: two policies attached to the same step, or to the same workflow, define the same hook. (0002)
