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
- **`And step "<step>" attempts:`** followed by a table scripting each attempt, with the columns `attempt` (the attempt number) and `outcome` (`success`, `failure`, `retriable failure`, `skipped` or `error`), and optionally `code`, `message`, `details` (JSON) for the reason, and `contributes` (a JSON object of keys and values contributed before ending). `error` means a recoverable failure escapes the running step (a throw, or an error returned through its signature), an abnormal termination; for `error`, the `message` column is the error's message. Attempts after the last row repeat the last row. (0008, 0054, 0083)
- **`And step "<step>" cannot be built because its constructor fails with "<message>"`**: building the step fails. (0008)
- **`And the abnormal termination of step "<step>" is retriable`**: the step's descriptor sets `abnormal termination retriable`; without this sentence it is false. (0024)
- **`And step "<step>" allows <n> retries`**: the step's retry budget: after the first attempt, at most `n` more. (0008, 0009)

## Data

- **`And the data bag is empty`**: the journey starts with no initial data. (0002)
- **`And the data bag contains:`** followed by a table with the columns `key` and `value`: the workflow instance is created with this initial data, so the journey starts with it. (0002, 0009)
- **`And the data bag contains a non-value as "<key>"`**: the initial data holds something that is not a value, such as a function, under this key. (0056)
- **`And step "<step>" contributes a non-value as "<key>"`**: the step contributes something that is not a value, such as a function. (0056)
- **`And step "<step>" fails with code "<code>" and details that are not a value`**: every attempt ends with a failure whose details are not a value. (0064)
- **`And step "<step>" ignores failures of its emit calls and carries on`**: when an emit call fails, the step catches or ignores the failure and goes on with the rest of its script. (0055)
- **`And step "<step>" keeps its contributor and step reporter`**: the step stores them where code outside its attempt can reach them. (0057)

## Journey IDs

- **`And the workflow has no ID generator`**: the workflow instance is created with the default journey ID, a UUID v4. (0009, 0061)
- **`And the workflow's ID generator returns "<id>"`**: the workflow instance is created with this journey ID. (0009, 0061)

## Input adapters

- **`And the workflow declares the input adapter "<adapter>" for the steps "<step>", "<step>"`**: attaches the adapter to these steps, one or more. For every key the sentences below do not mention, it returns nothing. (0060)
- **`And the input adapter "<adapter>" returns <value> for "<key>"`** (0002, 0060)
- **`And the input adapter "<adapter>" returns nothing for "<key>"`**: the input is resolved from the data bag. (0060)
- **`And the input adapter "<adapter>" fails with "<message>" for "<key>"`**: the adapter fails, by throwing or returning an error. (0002, 0060)
- **`And the input adapter "<adapter>" returns a non-value for "<key>"`**: the adapter returns something that is not a value, such as a function, where the language can express it. (0056)
- **`And the input adapter "<adapter>" requests data from the workflow "<key>" of type <type>`**: a required request, read from the data bag. (0060)

## Policies

- **`And a step policy "<policy>" defines the hook "<hook>"`**: a step policy whose hook does nothing beyond what other sentences add, and returns no lifecycle. Repeated with another hook for the same policy, it adds that hook to the same policy. (0002)
- **`And a workflow policy "<policy>" defines the hook "<hook>"`** (0002)
- **`And step "<step>" has the policies "<policy>", "<policy>"`**: attaches step policies, in this order. One or more names. (0002)
- **`And the workflow has the policies "<policy>", "<policy>"`**: attaches workflow policies, in this order. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests step data "<key>" of type <type>`**: a required request for data from the step. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests optional step data "<key>" of type <type>`** (0002)
- **`And the hook "<hook>" of policy "<policy>" changes the step data "<key>" it received to <value>`**: the hook changes the value it received, in place, as far as the language allows. (0027)
- **`And the hook "<hook>" of policy "<policy>" requests the step name`**: the hook asks for the name of the step it is acting on. (0002)
- **`And the hook "<hook>" of policy "<policy>" requests the failure reason`**: a required request for the failure's code, message and details; when the attempt reported no failure, the journey is aborted with `required data missing`. (0008, 0083)
- **`And the hook "<hook>" of policy "<policy>" requests the optional failure reason`**: the same request, optional; when the attempt reported no failure, it is answered absent. (0083)
- **`And the hook "<hook>" of policy "<policy>" requests the failure cause`**: why the failure hook was called: `failure`, `retries exhausted` or `abnormal termination`. (0008, 0024)
- **`And the hook "<hook>" of policy "<policy>" requests the retry cause`**: why the retry hook was called: `retriable failure` or `abnormal termination`. (0008)
- **`And the hook "<hook>" of policy "<policy>" requests the error`**: a required request for the error that ended the attempt, in an abnormal termination. (0008, 0083)

## Actions

- **`When the workflow is admitted`**: admission only; nothing runs. (0002)
- **`When the workflow runs`**: admission, then the journey. (0002)
- **`When the workflow is listed`**: the workflow's declaration is read without running anything. (0002)

## Outcomes

- **`Then admission is refused with the violations:`** followed by a table with the column `violation`, using the violation names below: the workflow is refused when it is built, or when the instance is handed to the executor, before any journey exists. The order of rows does not matter. (0002, 0032, 0042)
- **`Then the last event is "<event>"`** (0032)
- **`Then journey_aborted names no adapter`**: the journey's `journey_aborted` names no input adapter. (spec#87)
- **`Then no event was emitted`** (0032)
- **`Then no journey ID was produced`**: no workflow instance was created, so no journey ID exists; used only when the workflow is refused as it is built. (0032, 0061)
- **`Then no step ran`** (0002)
- **`Then the journey succeeded`** (0002)
- **`Then the journey was aborted`** (0002)
- **`Then the journey was aborted with the abort reason "<reason>"`**: the result's abort reason, from the list below. (0049)
- **`Then run was refused`** and **`Then run was refused with the message "<message>"`**: `run` reported a refusal to the developer instead of a journey result, carrying this message. (0049)
- **`Then the journey failed`** (0008)
- **`Then step "<step>" ended as <status> after <n> attempts`**: the step's final status, one of `succeeded`, `failed`, `skipped`, `not executed` or `aborted`, and how many attempts it took, both read from the event stream; an attempt counts from its `attempt_started`. (0008, spec#48, 0065)
- **`Then step "<step>" ended as aborted`**: the journey was aborted during this step, as `journey_aborted` says. (0009, 0065)
- **`Then the journey ID is a UUID v4`** (0009)
- **`Then the journey ID is "<id>"`** (0009)
- **`Then the journey_started event lists the initial keys "<key>", "<key>" without their values`**: one or more keys; the event carries exactly these keys and none of their values. (0009)
- **`Then the result names the failed step "<step>" with the code "<code>"`**: the journey failed with a reason of this code, and `journey_failed` names this step. The step's name is read from the event stream, since the result carries no step names. (0009, 0065)
- **`Then the result names the step "<step>" as where the journey was aborted, with the abort reason "<reason>"`**: the result's abort reason is this one, from the list below, and `journey_aborted` names this step. (0009, 0065)
- **`Then step "<step>" was built <n> times, each time as a new instance`** (0008)
- **`Then the result's data bag contains:`** followed by a table with the columns `key` and `value`: the result's data bag has at least these keys with these values. (0008)
- **`Then the result's data bag has no key "<key>"`** (0008)
- **`Then the result carries no data bag`**: the result of an aborted journey offers no data bag at all. Where the language makes reading it impossible, the step definition checks that by construction. (0085)
- **`Then no contribution of "<key>" was committed`**: no `contribution_committed` event names this key. (0085)
- **`Then the second journey's data bag contains:`** followed by a table with the columns `key` and `value`, after "the same executor runs the workflow twice". (0058)
- **`Then the result's journey ID is "<id>"`** (0065)
- **`Then the result's failure reason has the code "<code>"`**: the result of a failed journey explains it with a reason of this code. (0065)
- **`Then the result's failure has the cause "<cause>"`**: one of `failure`, `retries exhausted`, `abnormal termination` or `FailWorkflow`. (0083)
- **`Then the result's failure carries the error "<message>"`** and **`Then the result's failure carries no error`**: the error the result of a failed journey carries, by its message, or that it carries none. (0083)
- **`Then the result's failure carries no reason`** (0083)
- **`Then the result's abort carries the error "<message>"`** and **`Then the result's abort carries no error`**: the error the result of an aborted journey carries, by its message, or that it carries none. (0083)
- **`Then the hook "<hook>" of policy "<policy>" was not called`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" received the failure reason with code "<code>", message "<message>" and details <details>`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" received the cause "<cause>"`**: the failure cause or retry cause it requested. (0008)
- **`Then the hook "<hook>" of policy "<policy>" received an error`** (0008)
- **`Then the hook "<hook>" of policy "<policy>" received the error with the message "<message>"`** (0083)
- **`Then the hook "<hook>" of policy "<policy>" received no failure reason`**: its optional request for the failure reason was answered absent. (0083)
- **`Then step "<step>" was built with input "<key>" = <value>`** (0002)
- **`Then step "<step>" was built with input "<key>" absent`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" = <value>`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" absent`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received the step name "<step>"`**: on at least one call, the hook received this step name. (0002)
- **`Then the listing is:`** followed by a table with the columns `step`, `position`, `policies` and `adapter`, where `policies` lists the attached policies' names, separated by commas in declaration order, and `adapter` is the name of the step's input adapter; both are empty when there are none. (0002, 0060)

## Events

- **`Then the events include, in order:`** followed by an event table. (0002)
- **`Then the events are exactly:`** followed by an event table. (0002)

## Hooks, lifecycles and roles

What a hook does:

- **`And the hook "<hook>" of policy "<policy>" returns FinishWorkflow`** (0010)
- **`And the hook "<hook>" of policy "<policy>" returns FailWorkflow with code "<code>"`** (0010)
- **`And the hook "<hook>" of policy "<policy>" throws`**: the hook fails: it throws, or returns an error, as the language expresses a recoverable failure. (0010, 0054)
- **`And the hook "<hook>" of policy "<policy>" fails with "<message>"`**: the hook fails as above, with an error whose message is this text. (0083)
- **`And the hook "<hook>" of policy "<policy>" requests data from the workflow "<key>" of type <type>`**: a required request for data from the workflow, read from the data bag; input adapters are never used for a hook's request. (0010, 0041)
- **`And the hook "<hook>" of policy "<policy>" requests optional data from the workflow "<key>" of type <type>`** (0010)
- **`And the hook "<hook>" of policy "<policy>" requests the attempt number`** (0010)
- **`And the hook "<hook>" of policy "<policy>" requests the journey ID`** (0010)
- **`And the hook "<hook>" of policy "<policy>" contributes "<key>" = <value>`**: the hook contributes through its contributor before returning. (0010)
- **`And the hook "<hook>" of policy "<policy>" counts its calls and contributes the count as "<key>"`**: the policy instance holds a counter starting at 0; each call of this hook adds 1 to it and contributes it. (0058)
- **`And the policy "<policy>" fails when it is built`**: building an instance of the policy fails, by throwing or returning an error. (0058)
- **`And the policy "<policy>" fails with "<message>" when it is built`**: the same, with an error whose message is this text. (0083)
- **`And the hook "<hook>" of policy "<policy>" uses the kept contributor and step reporter of step "<step>" to contribute "<key>" = <value> and emit step_info "<message>"`**: the calls are made on handles whose attempt has ended. (0057)
- **`And the workflow provides the role "<role>" with the operation "<operation>"`**: the workflow implements this role; the operation records each call. (0010)
- **`And the hook "<hook>" of policy "<policy>" requests the role "<role>" and calls its operation "<operation>"`**: the hook declares the role as a parameter and calls the operation once. (0010)

What happened:

- **`Then the hook "<hook>" of policy "<policy>" was called <n> times`** (0010)
- **`Then the hooks were called in this order:`** followed by a table with the columns `policy` and `hook`, listing calls in the order they happened. (0010)
- **`Then the hook "<hook>" of policy "<policy>" received data from the workflow "<key>" = <value>`** (0010)
- **`Then the hook "<hook>" of policy "<policy>" received data from the workflow "<key>" absent`** (0010)
- **`Then the hook "<hook>" of policy "<policy>" received the attempt number <n>`** (0010)
- **`Then the hook "<hook>" of policy "<policy>" received the journey ID "<id>"`** (0010)
- **`Then the result names the step "<step>" whose hook failed the journey, with the code "<code>"`**: the journey failed by `FailWorkflow` with a reason of this code, and `journey_failed` names this step. (0010, 0065)
- **`Then the contribution of "<key>" is recorded as made by the hook "<hook>" of policy "<policy>"`**: the events record that this contribution came from that hook, not from a step. (0010)
- **`Then the operation "<operation>" of the role "<role>" was called <n> times`** (0010)
- **`And the operation "<operation>" of the role "<role>" throws`**: the role operation fails when called, by throwing or returning an error. (0049, 0054)

## Events and reporters

- **`And the workflow lists the reporters "<reporter>", "<reporter>"`**: one or more recording reporters, named for the scenario. (0011)
- **`And the executor uses its default dispatcher`**: the runner gives the executor no dispatcher factory, so it uses the default one. (0011, 0063)
- **`And the executor is given a dispatcher holding the reporter "<reporter>"`**: the executor is given a dispatcher factory; every dispatcher it creates holds this same reporter and adds the workflow's reporters as usual. The other "given a dispatcher" sentences describe the dispatchers such a factory creates. (0011, 0063)
- **`And the executor is given a dispatcher factory that fails`**: the factory fails, by throwing or returning an error, when the executor asks it for a dispatcher. (0063)
- **`And the executor is given a dispatcher holding the reporter "<reporter>" that ignores added reporters`** (0011)
- **`And the reporter "<reporter>" throws`**: the reporter fails (throws, or returns an error) on the first event it receives. (0011, 0054)
- **`And the reporter "<reporter>" throws on "<event>"`**: the reporter throws whenever it receives an event of this kind, and on no other. (0049)
- **`And the reporter "<reporter>" fails with "<message>" on "<event>"`**: the reporter fails, by throwing or returning an error whose message is this text, whenever it receives an event of this kind, and on no other. (0083)
- **`And the executor is given a dispatcher holding the reporter "<reporter>" that throws when a reporter is added`** (0049)
- **`And the executor is given a dispatcher holding the reporter "<reporter>" that throws when dispatching "<event>"`**: the dispatcher throws instead of delivering events of this kind, and delivers every other event to its reporter. (0049)
- **`And step "<step>" emits <kind> "<message>"`**, **`And step "<step>" emits <kind> "<message>" with data <data>`** and **`And step "<step>" emits <kind> "<message>" with data that is not a value`**: the step emits a `step_info`, `step_warning` or `step_error` event before ending; data that is not a value is, for example, a function. Emits, contributions and the other actions of a step happen in the order written. (0011, 0064)
- **`And the hook "<hook>" of policy "<policy>" emits <kind> "<message>"`**: the hook emits a `journey_info`, `journey_warning` or `journey_error` event before returning. (0011)
- **`Then the reporters "<reporter>", "<reporter>" received the same events`** (0011)
- **`Then the reporter "<reporter>" received the event "<event>"`** (0011)
- **`Then the reporter "<reporter>" received no event`** (0011)
- **`Then the reporter "<reporter>" received the event "<event>" <n> times`** (0049)
- **`Then the reporter "<reporter>" did not receive the event "<event>"`** (spec#47)
- **`Then every event carries the journey ID "<id>" and the workflow name "<workflow>", with increasing sequence numbers`** (0011)
- **`Then no engine event carries the value of "<key>"`**: no event of the engine catalogue contains the value of this key, anywhere. (0011)
- **`Then no event carries the message "<message>"`** (0057, 0064)

## The executor

- **`And step "<step>" is asynchronous`**: the scripted step runs asynchronously. (0012)
- **`And the executor accepts only synchronous steps, hooks and reporters`**: the scenario uses a synchronous-only executor. (0012)
- **`When the same executor runs the workflow twice, with a new instance each time`**: one executor runs two journeys, one after the other, each with a new workflow instance created the same way. (0012)
- **`Then run returned a result instead of throwing`** (0012)
- **`Then the two journeys have different journey IDs`** (0012)
- **`Then the second journey's events are the first journey's events, apart from the journey ID and timestamps`** (0012)
- **`Then each instance's reporter "<reporter>" received only its own journey's events`**: the reporter is created with each workflow instance. (0012)
- **`Then the reporter "<reporter>" was made with the journey ID "<id>"`**: the reporter received this journey ID when the workflow instance made it, before any event. (0061)

## Hook names

The hook names of proposal 0010: `on step success`, `on step failure`, `on step retry`, `on step abnormal termination`, `on workflow success`, `on workflow failure`. (0002; defined by 0010)

## Event names

The engine catalogue of proposal 0011 as amended by proposal 0040. Facts: `journey_started`, `attempt_started`, `input_adapter_supplied`, `input_adapter_failed`, `optional_input_absent`, `step_succeeded`, `step_failed`, `step_skipped`, `step_abnormal_termination`, `hook_called`, `contribution_committed`, `contributions_discarded`, `data_overwritten`, `journey_aborted`. Decisions: `step_retrying`, `step_given_up`, `journey_succeeded`, `journey_failed`; and the events steps and hooks emit: `step_info`, `step_warning`, `step_error`, `journey_info`, `journey_warning`, `journey_error`. (0011, 0040)

## Abort reasons

The abort reasons of a journey's result (0009, 0032, 0042, 0054, 0056, 0058): `step could not be built`, `required data missing`, `wrong type`, `invalid lifecycle`, `policy could not be built`, `not a value`, `hook failed`, `reporter failed`.

## Violation names

- **`hook defined twice`**: two policies attached to the same step, or to the same workflow, define the same hook. (0002)
- **`duplicate step name`**: two steps in one workflow have the same name. (0008)
- **`role not provided`**: a policy attached to the workflow requests a role the workflow does not provide. (0010)
- **`mode not accepted`**: a step, hook or reporter runs in an execution mode the executor does not accept. (0012)
- **`step adapted twice`**: two input adapters are attached to the same step. (0060)
- **`input adapter for unknown step`**: an input adapter is attached to a step the workflow does not have. (0060)
