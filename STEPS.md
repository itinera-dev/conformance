# Step catalogue

The only sentences a conformance case may use, with their exact meaning. Rules for using them are in [FORMAT.md](FORMAT.md). In the sentences, `<name>` is a parameter: a quoted string for names and keys, a JSON value for values, a type from the neutral vocabulary for types.

Each sentence names the proposal that introduced it.

## Building a workflow

- **`Given a workflow "<workflow>" with the steps:`** followed by a table with the column `step`, one row per step in declaration order. Declares a workflow whose steps are scripted test steps. (0002)
- **`And step "<step>" requests input "<key>" of type <type>`**: the step declares a required input. (0002)
- **`And step "<step>" requests optional input "<key>" of type <type>`**: the step declares an optional input. (0002)
- **`And step "<step>" contributes "<key>" = <value>`**: on every attempt, the step contributes this key and value before ending. Repeated for the same key, the contributions happen in the order written. (0002)
- **`And step "<step>" succeeds`**: every attempt of the step ends with success. (0002)
- **`And step "<step>" changes its input "<key>" to <value>`**: before ending, the step changes the value it received for this input, in place, to this content, as far as the language allows; in a language where received values cannot be changed, it does nothing. (0027)
- **`And step "<step>" contributes "<key>" = <value> and then changes it to <value>`**: the step contributes the first value, then changes that same object in place to the second content before ending, as far as the language allows. (0027)
- **`And step "<step>" attempts:`** followed by a table scripting each attempt, with the columns `attempt` (the attempt number) and `outcome` (`success`, `failure`, `retriable failure`, `skipped` or `error`), and optionally `code`, `message`, `details` (JSON) for the reason, and `contributes` (a JSON object of keys and values contributed before ending). `error` means an error escapes the running step, an abnormal termination. Attempts after the last row repeat the last row. (0008)
- **`And step "<step>" cannot be built because its constructor fails with "<message>"`**: building the step fails. (0008)
- **`And the abnormal termination of step "<step>" is retriable`**: the step's descriptor sets `abnormal termination retriable`; without this sentence it is false. (0024)
- **`And step "<step>" allows <n> retries`**: the step's retry budget: after the first attempt, at most `n` more. Provisional until the retry configuration of [itinera-dev/spec#9](https://github.com/itinera-dev/spec/issues/9) is accepted. (0008)

## Data

- **`And the data bag is empty`**: the journey starts with no initial data. (0002)
- **`And the data bag contains:`** followed by a table with the columns `key` and `value`: the workflow instance is created with this initial data, so the journey starts with it. (0002, 0009)

## Journey IDs

- **`And the workflow has no ID generator`**: the workflow uses its default generator. (0009)
- **`And the workflow's ID generator returns "<id>"`**: the workflow defines a custom ID generator returning this value. (0009)

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
- **`And the hook "<hook>" of policy "<policy>" changes the step data "<key>" it received to <value>`**: the hook changes the value it received, in place, as far as the language allows. (0027)
- **`And the hook "<hook>" of policy "<policy>" requests the step name`**: the hook asks for the name of the step it is acting on. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests the failure reason`**: the failure's code, message and details. (0008)
- **`And the hook "<hook>" of policy "<policy>" requests the failure cause`**: why the failure hook was called: `failure`, `retries exhausted` or `abnormal termination`. (0008, 0024)
- **`And the hook "<hook>" of policy "<policy>" requests the retry cause`**: why the retry hook was called: `retriable failure` or `abnormal termination`. (0008)
- **`And the hook "<hook>" of policy "<policy>" requests the error`**: the error of an abnormal termination. (0008)

## Actions

- **`When the workflow is admitted`**: admission only; nothing runs. (0002)
- **`When the workflow runs`**: admission, then the journey. (0002)
- **`When the workflow is listed`**: the workflow's declaration is read without running anything. (0002)

## Outcomes

- **`Then admission is refused with the violations:`** followed by a table with the column `violation`, using the violation names below. The order of rows does not matter. (0002)
- **`Then no step ran`** (0002)
- **`Then the journey succeeded`** (0002)
- **`Then the journey was aborted`** (0002)
- **`Then the journey failed`** (0008)
- **`Then step "<step>" ended as <status> after <n> attempts`**: the step's final status in the journey's result, one of `succeeded`, `failed`, `skipped` or `not executed`, and how many attempts it took. (0008)
- **`Then step "<step>" ended as aborted`**: the journey was aborted during this step; its status in the result is `Aborted`. (0009)
- **`Then the journey ID is a UUID v4`** (0009)
- **`Then the journey ID is "<id>"`** (0009)
- **`Then the journey started event lists the initial keys "<key>", "<key>" without their values`**: one or more keys; the event carries exactly these keys and none of their values. (0009)
- **`Then the result names the failed step "<step>" with the code "<code>"`**: the result of a failed journey names the step that failed and the code of its reason. (0009)
- **`Then the result names the step "<step>" as where the journey was aborted, with the abort reason "<reason>"`**: using an abort reason name from the list below. (0009)
- **`Then step "<step>" was built <n> times, each time as a new instance`** (0008)
- **`Then the result's data bag contains:`** followed by a table with the columns `key` and `value`: the result's data bag has at least these keys with these values. (0008)
- **`Then the result's data bag has no key "<key>"`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" was not called`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" received the failure reason with code "<code>", message "<message>" and details <details>`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" received the cause "<cause>"`**: the failure cause or retry cause it requested. (0008)
- **`Then the hook "<hook>" of policy "<policy>" received an error`** (0008)
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

## Event names

Until the events proposal ([itinera-dev/spec#11](https://github.com/itinera-dev/spec/issues/11)) is accepted, cases use these provisional names: `input adapter supplied`, `input adapter failed`, `optional input absent` (0002); `step skipped`, `contributions discarded`, `data overwritten` (0008); `journey started`, `attempt started` (0009).

## Abort reasons

The abort reasons of a journey's result (0009): `step could not be built`, `required data missing`, `wrong type`, `hook threw`, `invalid lifecycle`, `reporter threw`.

## Violation names

- **`hook defined twice`**: two policies attached to the same step, or to the same workflow, define the same hook. (0002)
- **`duplicate step name`**: two steps in one workflow have the same name. (0008)
