# Step catalogue

The only sentences a conformance case may use, with their exact meaning. Rules for using them are in [FORMAT.md](FORMAT.md). In the sentences, `<name>` is a parameter: a quoted string for names and keys, a JSON value for values, a type from the neutral vocabulary for types.

Each sentence names the proposal that introduced it.

A **null-like value** is what a language has for no value at all, such as `null` in Java, or `null` or `undefined` in JavaScript. The sentences that use it appear only in scenarios tagged `@unexpected-result`, so a language without one claims the tag as impossible. (0122)

## Building a workflow

- **`Given a workflow "<workflow>" with the steps:`** followed by a table with the column `step`, one row per step in declaration order. Declares a workflow whose steps are scripted test steps. (0002)
- **`And step "<step>" requests input "<key>" of type <type>`**: the step declares a required input. (0002)
- **`And step "<step>" requests optional input "<key>" of type <type>`**: the step declares an optional input. (0002)
- **`And step "<step>" contributes "<key>" = <value>`**: on every attempt, the step contributes this key and value before ending. Repeated for the same key, the contributions happen in the order written. (0002)
- **`And step "<step>" succeeds`**: every attempt of the step ends with success. (0002)
- **`And step "<step>" changes its input "<key>" to <value>`**: before ending, the step changes the value it received for this input, in place, to this content, as far as the language allows; in a language where received values cannot be changed, it does nothing. (0027)
- **`And step "<step>" contributes "<key>" = <value> and then changes it to <value>`**: the step contributes the first value, then changes that same object in place to the second content before ending, as far as the language allows. (0027)
- **`And step "<step>" attempts:`** followed by a table scripting each attempt, with the columns `attempt` (the attempt number) and `outcome` (`success`, `failure`, `skipped` or `error`), and optionally `code`, `message`, `details` (JSON) for the reason, and `contributes` (a JSON object of keys and values contributed before ending). `error` means a recoverable failure escapes the running step (a throw, or an error returned through its signature), an abnormal termination; for `error`, the `message` column is the error's message. Attempts after the last row repeat the last row. (0008, 0054, 0083, 0106)
- **`And step "<step>" cannot be built because its constructor fails with "<message>"`**: building the step fails. (0008)
- **`And step "<step>" returns no outcome`**: every attempt of the step ends by returning a null-like value instead of an outcome; for an asynchronous step, by resolving to one. (0122)
- **`And step "<step>" is built as a null-like value`**: building the step gives a null-like value instead of a step. (0122)
- **`And step "<step>" does not retry abnormal terminations`**: the step's descriptor turns `retry on abnormal termination` off; without this sentence it is on. (0024, 0106)
- **`And step "<step>" allows <n> retries`**: the step's retry budget: after the first attempt, at most `n` more. (0008, 0009)
- **`And step "<step>" has a rescue step`**: the step's descriptor holds a rescue step, named `<step>_rescue`. The sentences about a step that a scripted step can follow (its inputs, services, contributions, outcomes, emits, and how it is built) script the rescue step under that name, as for any scripted step; it has no retry budget or policies of its own. An input adapter or a service provider is attached to it by that name, as to a step. (0003, 0098)
- **`And step "<step>" requests rescued step data "<key>" of type <type>`** and **`And step "<step>" requests optional rescued step data "<key>" of type <type>`**: the rescue step requests, required or optional, what the failed attempt of the step it rescues contributed under this key. (0003)
- **`And step "<step>" requests the failure reason`** and **`And step "<step>" requests the error`**: the rescue step requests the failure reason or the error of the failed attempt of the step it rescues, as a hook does. A rescue step's requests are declared in the order their sentences are written. (0003)

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
- **`And the workflow's ID generator returns "<id>"`**: the ID generator produces this journey ID, with which the workflow instance is created. (0009, 0061)
- **`And the workflow's ID generator returns something that is not a string`**: such as a null-like value or a number. Used only in scenarios tagged `@non-string-journey-id`. (0122)

## Input adapters

An input adapter's own requests are declared in the order their sentences are written. (spec#92)

- **`And the workflow declares the input adapter "<adapter>" for the steps "<step>", "<step>"`**: attaches the adapter to these steps, one or more, each as often as it is named; a rescue step is named `<step>_rescue`. For every key the sentences below do not mention, it returns nothing. A second declaration of a name already declared declares a second adapter with that name, which no other sentence scripts. (0060, 0098, 0116)
- **`And the input adapter "<adapter>" returns <value> for "<key>"`** (0002, 0060)
- **`And the input adapter "<adapter>" returns nothing for "<key>"`**: the input is resolved from the data bag. (0060)
- **`And the input adapter "<adapter>" fails with "<message>" for "<key>"`**: the adapter fails, by throwing or returning an error. (0002, 0060)
- **`And the input adapter "<adapter>" returns a null-like value for "<key>"`**: the adapter returns a null-like value, not the language's form of nothing. (0122)
- **`And the input adapter "<adapter>" returns a non-value for "<key>"`**: the adapter returns something that is not a value, such as a function, where the language can express it. (0056)
- **`And the input adapter "<adapter>" requests data from the workflow "<key>" of type <type>`**: a required request, read from the data bag. (0060)
- **`And the input adapter "<adapter>" requests the step name and returns it for "<key>"`**: the adapter requests the name of the step being built and, when called for that input, returns that name as a string. (0098)
- **`And the input adapter "<adapter>" requests the data bag`**: the adapter declares read access to the data bag. Reads through it emit nothing and abort nothing. (0091)
- **`And the input adapter "<adapter>" returns "<key>" of type <type>, read from the data bag, for "<input>"`**: when called for that input, the adapter reads that key through its access, and returns the value if it found one of that type, or nothing otherwise. (0091)
- **`And the input adapter "<adapter>" writes "<key>" = <value> through its data bag access`**: on every call, the adapter writes through its access, as far as the language allows, then goes on. (0091)
- **`And the input adapter "<adapter>" keeps its data bag access when called for step "<step>", and returns "<key>" of type <type>, read through that kept access, for "<input>" when called for step "<step>"`**: the adapter keeps the access it was given for the first step's inputs, and later reads through that kept access, not the one it is given for the second step. (0091)

## Policies

A hook's requests, made by the sentences below and in "Hooks, lifecycles and roles", are declared in the order their sentences are written, whatever their kind. (spec#92)

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
- **`And the hook "<hook>" of policy "<policy>" requests the retry cause`**: why the retry hook was called: `failure` or `abnormal termination`. (0008, 0106)
- **`And the hook "<hook>" of policy "<policy>" requests the error`**: a required request for the error that ended the attempt, in an abnormal termination. (0008, 0083)

## Services

Every instance a provider makes is labelled with the provider's name and how many instances that provider has made in the journey, counting from 1, such as `stock 1`, unless a sentence below labels it otherwise. A service of type `labeller` has one operation, which returns its instance's label. A provider's own requests are declared in the order their sentences are written. (0095)

- **`And step "<step>" requests the service "<key>" of type <service type>`**: the step declares a service. When it runs, before the rest of its script, it calls the service's operation once, and the runner records the label it returned; an error from that operation escapes the step, which makes an abnormal termination. Repeated for another key, the services are declared in the order written; repeated for the same key, the step requests that key twice. (0095)
- **`And the workflow declares the service provider "<provider>" for "<key>" of type <service type>, once per journey`**: a provider of journey scope, attached to no step unless the sentence below attaches it. (0095)
- **`And the workflow declares the service provider "<provider>" for "<key>" of type <service type>, for each attempt`**: a provider of attempt scope, attached to no step unless the sentence below attaches it. (0095)
- **`And the service provider "<provider>" serves only the steps "<step>", "<step>"`**: attaches the provider to these steps, one or more, each as often as it is named; a rescue step is named `<step>_rescue`. (0095, 0098, 0116)
- **`And the service provider "<provider>" requests the step name`** (0095)
- **`And the service provider "<provider>" requests the attempt number`** (0095)
- **`And the service provider "<provider>" requests the journey ID`** (0095)
- **`And the service provider "<provider>" requests data from the workflow "<key>" of type <type>`**: a required request, read from the data bag. (0095)
- **`And the service provider "<provider>" requests optional data from the workflow "<key>" of type <type>`** (0095)
- **`And the service provider "<provider>" labels each instance with the value it received for "<key>"`**: instead of its name and count, each instance it makes is labelled with the string it received for that request. (0095)
- **`And the service provider "<provider>" fails with "<message>"`**: on every call, the provider fails, by throwing or returning an error whose message is this text. (0095)
- **`And the service provider "<provider>" fails with "<message>" when it receives "<value>" for "<key>"`**: the provider fails as above only on a call where it received this string for that request, and otherwise makes an instance. (0095)
- **`And the service provider "<provider>" emits <kind> "<message>"`** and **`And the service provider "<provider>" emits <kind> "<message>" with data that is not a value`**: on every call, the provider emits a `journey_info`, `journey_warning` or `journey_error` event before returning. (0095)
- **`And the service provider "<provider>" makes instances of <implementation>`**: every instance this provider makes is of this implementation of `labeller`: `first labeller` or `second labeller`. (0104)
- **`And the service provider "<provider>" supplies the data <data> with each instance`** and **`And the service provider "<provider>" supplies data that is not a value with each instance`**: on every call that makes an instance, the provider supplies this data with it, as JSON; data that is not a value is, for example, a function. (0104)
- **`And the service provider "<provider>" returns nothing`**: on every call, the provider returns neither an instance nor an error. Used only in scenarios tagged `@no-instance`. (0095)
- **`And the service provider "<provider>" returns a null-like value`**: on every call, the provider returns a null-like value, not the language's form of nothing. (0122)
- **`And the service provider "<provider>" is asynchronous`** (0095)
- **`And the services the provider "<provider>" makes fail with "<message>" when used`**: the operation of every instance this provider makes fails, by throwing or returning an error whose message is this text. (0095)
- **`Then the service provider "<provider>" was called <n> times`**: counting every call, whether it made an instance or failed; a provider never called was called 0 times. (0095)
- **`Then step "<step>" was given the service "<key>" labelled "<label>" for attempt <n>`**: the step built for that attempt received an instance with this label. (0095)
- **`Then the service provider "<provider>" received the step name "<step>"`**: on at least one call. (0095)
- **`Then the service provider "<provider>" received the attempt number <n>`**: on at least one call. (0095)
- **`Then the service provider "<provider>" received the journey ID "<id>"`** (0095)
- **`Then the service provider "<provider>" received data from the workflow "<key>" absent`** (0095)

Service types, used only in these sentences: `labeller`, described above, and `meter`, an unrelated type whose one operation returns an integer reading, which a step requesting a `labeller` never accepts. (0095)

Implementations of `labeller`, used only in these sentences: `first labeller`, which every provider of a `labeller` makes unless a sentence says otherwise, and `second labeller`. They are two types of the runner's own, which label their instances in the same way, each with a name of its own as the language reports it at run time. (0104)

## Actions

- **`When the workflow is admitted`**: admission only; nothing runs. (0002)
- **`When the workflow runs`**: admission, then the journey. (0002)
- **`When the workflow is listed`**: the workflow's declaration is read without running anything. (0002)

## Outcomes

- **`Then admission is refused with the violations:`** followed by a table with the column `violation`, using the violation names below: the workflow is refused when it is built, or when the instance is handed to the executor, before any journey exists. The order of rows does not matter. (0002, 0032, 0042)
- **`Then the last event is "<event>"`** (0032)
- **`Then journey_aborted names no adapter`**: the journey's `journey_aborted` names no input adapter. (spec#87)
- **`Then no event was emitted`** (0032)
- **`Then creating the workflow instance failed`**: the application's own code creating the workflow instance reported a failure, as the language's own error, so no journey ran. (0122)
- **`Then no journey ID was produced`**: no workflow instance was created, so no journey ID exists; used only when the workflow is refused as it is built. (0032, 0061)
- **`Then no step ran`** (0002)
- **`Then the journey succeeded`** (0002)
- **`Then the journey was aborted`** (0002)
- **`Then the journey was aborted with the abort reason "<reason>"`**: the result's abort reason, from the list below. (0049)
- **`Then run was refused`** and **`Then run was refused with the message "<message>"`**: `run` reported a refusal to the developer instead of a journey result, carrying this message. (0049)
- **`Then the journey failed`** (0008)
- **`Then step "<step>" ended as <status> after <n> attempts`**: the step's final status, one of `succeeded`, `failed`, `skipped`, `not executed`, `rescuing` or `aborted`, and how many attempts it took, both read from the event stream; an attempt counts from its `attempt_started`. The status is `aborted` when `journey_aborted` names the step and no `step_succeeded`, `step_skipped` or `step_given_up` of that step came before it: a step whose status was already final when the journey was aborted keeps it. A step whose last decision is `step_rescuing` or `step_rescued`, with no `attempt_started` of it after that decision, is `rescuing`, or `aborted` when the journey was aborted. (0008, spec#48, 0065, spec#89, 0003)
- **`Then step "<step>" ended as aborted`**: the journey was aborted while this step was executing or about to be retried: `journey_aborted` names it, and no `step_succeeded`, `step_skipped` or `step_given_up` of that step came before it; or while it was being rescued: its last decision is `step_rescuing` or `step_rescued`, with no `attempt_started` of it after that decision, and the journey was aborted. (0009, 0065, spec#89, 0003)
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
- **`Then step "<step>" was built with rescued step data "<key>" = <value>`** and **`Then step "<step>" was built with rescued step data "<key>" absent`**: what the rescue step received for its request of data from the step it rescues. (0003)
- **`Then step "<step>" received the failure reason with code "<code>", message "<message>" and details <details>`** and **`Then step "<step>" received the error with the message "<message>"`**: what the rescue step received for its request of the failure reason or the error. (0003)
- **`Then step "<step>" was built for attempt <n> with input "<key>" = <value>`**: the step built for that attempt received this value. (0091)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" = <value>`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received step data "<key>" absent`** (0002)
- **`Then the hook "<hook>" of policy "<policy>" received the step name "<step>"`**: on at least one call, the hook received this step name. (0002)
- **`Then the listing is:`** followed by a table with the columns `step`, `position`, `policies` and `adapter`, where `policies` lists the attached policies' names, separated by commas in declaration order, and `adapter` is the name of the step's input adapter; both are empty when there are none. An optional column `rescue` holds the name of the step's rescue step, empty when it has none. An optional column `services` lists each service the step requests as `<key>: <provider>`, with the name of the provider that serves it, separated by commas in the order the step declares them, empty when it requests none. Optional columns `rescue adapter` and `rescue services` show the rest of the step's rescue section: the name of the rescue step's input adapter, and the services the rescue step requests, written as in `services`; each is empty when the step has no rescue step or, respectively, when its rescue step has no input adapter or requests no services. An optional column that is absent is not compared. (0002, 0060, 0003, 0095, 0098)

## Events

- **`Then the events include, in order:`** followed by an event table. (0002)
- **`Then the events are exactly:`** followed by an event table. (0002)

## Hooks, lifecycles and roles

What a hook does:

- **`And the hook "<hook>" of policy "<policy>" returns FinishWorkflow`** (0010)
- **`And the hook "<hook>" of policy "<policy>" returns FailWorkflow with code "<code>"`** (0010)
- **`And the hook "<hook>" of policy "<policy>" returns something that is not a lifecycle`**: the hook returns a value that is neither the language's form of nothing nor a lifecycle, such as a string. Used only in scenarios tagged `@unexpected-result`. (0122)
- **`And the hook "<hook>" of policy "<policy>" returns a null-like value`**: the hook returns a null-like value, not the language's form of nothing. (0122)
- **`And the hook "<hook>" of policy "<policy>" returns a value`**: used only for a workflow hook: it returns a value, such as a string, as far as the language allows; in a language where it cannot, it returns nothing. (0122)
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
- **`And the policy "<policy>" is built as a null-like value`**: building an instance of the policy gives a null-like value instead of a policy. (0122)
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

## Global metadata

- **`And the workflow instance is created with the global metadata:`** followed by a table with the columns `key` and `value`: the workflow instance is created with this initial global metadata, its keys set in the order of the rows. (0102)
- **`And the workflow instance is created with a non-value as global metadata "<key>"`**: the initial global metadata holds something that is not a value, such as a function, under this key. (0102)
- **`And step "<step>" sets the global metadata "<key>" to <value>`** and **`And step "<step>" sets the global metadata "<key>" to a non-value`**: on every attempt, the step sets this entry through its step reporter; a non-value is, for example, a function. Setting, emits, contributions and the other actions of a step happen in the order written. (0102)
- **`And the hook "<hook>" of policy "<policy>" sets the global metadata "<key>" to <value>`**: the hook sets this entry before returning. With the events the hook emits, it happens in the order written. (0102)
- **`And the service provider "<provider>" sets the global metadata "<key>" to <value>`**: on every call, the provider sets this entry before returning. With the events the provider emits, it happens in the order written. (0102)
- **`And the reporter "<reporter>" fails when it receives the global metadata "<key>"`**: the reporter fails, by throwing or returning an error, whenever it receives an entry of this key, and on no other entry and no event. (0102)
- **`Then the reporter "<reporter>" received the global metadata:`** followed by a table with the columns `key`, `value` and `after`: the reporter received exactly these entries, in this order. `value` is JSON. `after` is the kind of the last event the reporter received before the entry, or `none` when the entry came before every event. An empty cell is not compared. (0102)
- **`Then the reporters "<reporter>", "<reporter>" received the same global metadata`**: the same entries, in the same order. (0102)
- **`Then no engine event carries the global metadata value of "<key>"`**: no event of the engine catalogue, `global_metadata_set` included, contains the value set for this key, anywhere. (0102)

## The executor

- **`And step "<step>" is asynchronous`**: the scripted step runs asynchronously. (0012)
- **`And the hook "<hook>" of policy "<policy>" is asynchronous`**: the hook runs asynchronously, and what it does, including how it fails or what it returns, happens when its future or promise completes. (0122)
- **`And the executor accepts only synchronous steps, hooks and reporters`**: the scenario uses a synchronous-only executor, which accepts only synchronous service providers too. (0012, 0095)
- **`When the same executor runs the workflow twice, with a new instance each time`**: one executor runs two journeys, one after the other, each with a new workflow instance created the same way. (0012)
- **`Then run returned a result instead of throwing`** (0012)
- **`Then the two journeys have different journey IDs`** (0012)
- **`Then the second journey's events are the first journey's events, apart from the journey ID and timestamps`** (0012)
- **`Then each instance's reporter "<reporter>" received only its own journey's events`**: the reporter is created with each workflow instance. (0012)
- **`Then the reporter "<reporter>" was made with the journey ID "<id>"`**: the reporter received this journey ID when the workflow instance made it, before any event. (0061)

## Value conversions

Sentences and types for the capability value conversions (proposal 0113), used only in scenarios tagged `@capability-value-conversions`. A **converted type** is a type of the runner's own, standing for one of an application's classes, that the runner gives the value conversions its language uses: code that turns an object of the type into a value when the object is captured, and that turns a value into the type, or checks that a value is of the type, when a request reads it. A converted type is written wherever a sentence takes a `<type>`, so a step, a hook, a rescue step, an input adapter or a service provider can request one, and an input adapter can read one through its access to the data bag. (0113)

Converted types, used only in these scenarios (0113):

- **`throwing record`**: both its conversions fail on every call, by throwing or returning an error whose message is `conversion failed`: turning an object of the type into a value, and turning any value into the type.
- **`rejected record`**: when a request reads a value as this type, the conversion or check reports that the value is not of the type, whatever the value, as its language lets a conversion or a check say so, without throwing or returning an error.

Capturing an object of a converted type:

- **`And step "<step>" contributes a throwing record as "<key>"`**: on every attempt, the step contributes an object of `throwing record` under this key. (0113)
- **`And step "<step>" emits <kind> "<message>" with a throwing record as data`**: the step emits a `step_info`, `step_warning` or `step_error` event whose data is an object of `throwing record`. Emits, contributions and the other actions of a step happen in the order written. (0113)
- **`And step "<step>" sets the global metadata "<key>" to a throwing record`**: on every attempt, the step sets this entry, through its step reporter, to an object of `throwing record`. (0113)
- **`And step "<step>" fails with code "<code>" and a throwing record as details`**: every attempt ends with a failure of this code whose details are an object of `throwing record`. (0113)
- **`And the input adapter "<adapter>" returns a throwing record for "<key>"`**: when called for this input, the adapter returns an object of `throwing record`. (0113)
- **`And the service provider "<provider>" supplies a throwing record as data with each instance`**: on every call that makes an instance, the provider supplies an object of `throwing record` as its data. (0113)
- **`And the data bag contains a throwing record as "<key>"`**: the workflow instance is created with initial data holding an object of `throwing record` under this key. (0113)
- **`And the workflow instance is created with a throwing record as global metadata "<key>"`**: the initial global metadata holds an object of `throwing record` under this key. (0113)

What `run` refused:

- **`Then the refusal lists the key "<key>"`**: the refusal `run` reported lists this key among the keys of initial data or initial global metadata it concerns, as its language reports them. (0113)

## Test support

Sentences for the capability test support (proposal 0108), used only in scenarios tagged `@capability-testing`. The runner reaches each part through its language's own test support, never through its own recording or scripting. A **mistake in a test** is reported as the language's test support reports it, which may happen while the sentence that makes the mistake runs or during the `When` sentence; the runner captures it from either and checks it with "the test stopped before the journey". A mistake in reading a scripted run's record is reported after the journey, while the sentence that reads it runs (0119). The names of mistakes are listed under "Test mistakes" below. In these scenarios a scripted test step declares a contributor and a step reporter, unless "declares no contributor and no reporter" says otherwise. (0108)

The recording reporter and the path:

- **`And the instance has the recording reporter of test support`**: the runner adds its language's recording reporter to the workflow instance, after the reporters the workflow lists. It is not one of the reporters a scenario names, and the sentences about the event stream as a whole do not read it. (0108)
- **`Then the path is:`** followed by a table with the column `line`: the path read from that recording reporter is exactly these lines, in this order. (0108)
- **`Then the path is empty`** (0108)
- **`Then the recording reporter of test support kept the same events as the reporter "<reporter>"`**: the same events, in the same order. (0108)
- **`Then the recording reporter of test support kept the global metadata:`** followed by a table with the columns `key` and `value`: that recording reporter holds exactly these keys, each with the latest value it received; `value` is JSON, and the order of rows does not matter. (0108)

Fake providers:

- **`And the test replaces the service provider "<provider>" with a fake that makes instances of <implementation>`**: through its language's test support, the runner replaces this provider of the instance with a fake, a function that makes an instance of this implementation of `labeller`, labelled `fake <n>`, where `n` counts the fake's calls in the journey from 1. Whatever other sentences say the provider itself does no longer happens, while its requests, its scope and its attachment stay as declared. (0108)
- **`And the test replaces the service provider "<provider>" with a fake that makes instances of <implementation> and supplies the data <data>`**: the same, and the fake supplies this data, as JSON, with each instance. (0108)
- **`And the test replaces the service provider "<provider>" with a fake that fails with "<message>"`**: the same, but the fake fails on every call, by throwing or returning an error whose message is this text. (0108)
- **`And the test replaces the service provider "<provider>" with a fake that makes meters`**: the same, but the fake makes services of type `meter`, another service than a provider of a `labeller` makes. (0108)
- **`Then the fake of "<provider>" was called <n> times`**: counting every call, whether it made an instance or failed. (0108)

Scripted runs:

- **`And the script says:`** followed by a table with the columns `step` and `attempt`, and optionally `contributes`, `emits`, `emit message`, `sets global metadata`, `ending`, `code` and `message`. Each row says what the attempts it chooses do, in the language's own words for the script of proposal 0108. The rows are written in the order given, and each row whose step differs from the row before names that step, with `step` for the first and `and step` for each next one, so a step whose rows another step's interrupt is named again; a rescue step is named `<step>_rescue`. `attempt` chooses the attempts: a number, which may be one the step can never have, such as `0`, `-1` or `1.5` (0119), `every` for every attempt, or `remaining` for every attempt not yet described, which never starts a step's rows; the first row of a step written with `1` may be written without saying it. `contributes` is a JSON object, contributed in the order its keys are written, which the runner keeps when it reads it. `emits` is `step_info`, `step_warning` or `step_error`, emitted with `emit message`. `sets global metadata` is a JSON object, set in the order its keys are written. `ending` is `success`, `failure` (with `code`), `skipped` (with a `code` when the skip has a reason), `abnormal termination` (with its error's `message`, the only ending that uses `message`) or `real run`, which plays nothing and runs the real step; a row with `real run` has no other column filled. (0108)
- **`And the script ensures every step is scripted`** (0108)
- **`When the workflow runs with the script`**: the runner writes the script through its language's test support and runs the instance with it, on the local executor of the workflow's mode. That executor has no dispatcher factory from the runner, so the runner adds its own recording reporter to the instance as its first reporter, before the reporters the workflow lists, and every sentence about the event stream as a whole reads that reporter; the sentences in which the executor is given a dispatcher or a dispatcher factory are not used with this one. A mistake in writing the script is reported as it is written, so during this sentence. (0108)
- **`And step "<step>" declares no contributor and no reporter`**: the scripted test step neither contributes, nor emits, nor sets global metadata, and declares neither a contributor nor a step reporter. Used only in scenarios tagged `@undeclared-handles`. (0108)
- **`Then the test stopped before the journey, naming:`** followed by a table with the column `mistake`, and optionally `step`, `attempt` and `provider`: the test support stopped the test before any journey started, as the language reports a misuse in a declaration, and what it reported names, for each row, the step, the attempt number, which may be one the step can never have (0119), and the provider given in that row. `mistake` is one of the test mistakes below; the runner checks that each row's mistake is reported, as the language words it, and that nothing else is; the order of rows does not matter. (0108)
- **`Then the scripted run's record of step "<step>" holds the attempts <n>, <n>`**: one or more numbers, in order: the attempts handed to the construction of this step, scripted or real. (0108)
- **`Then the scripted run's record of step "<step>" holds no attempt`** (0108)
- **`Then reading the scripted run's record of step "<step>" stops the test as the mistake "<mistake>"`**: the runner reads the scripted run's record of this step, by name, through its language's test support, after the journey, and the test support stops the test there, as the language reports a misuse in a declaration, with what it reported naming this mistake and this step, and nothing else. (0119)
- **`Then attempt <n> of step "<step>" in the scripted run's record read the input "<key>" = <value>`** and **`Then attempt <n> of step "<step>" in the scripted run's record read the rescued step data "<key>" = <value>`**: what that attempt's step was built with, read through the record. (0108)
- **`Then reading attempt <n> of step "<step>" in the scripted run's record reads nothing`**: reading this attempt of this step's record, by number, reads nothing, as the language says a value is absent, and does not stop the test. (0119)

Recorders:

- **`When step "<step>" runs alone`**: the runner builds the scripted test step outside any journey, as a test does, and calls its run itself, with a contributor lent by the contributions recorder and a step reporter lent by the step event reporter of its language's test support. The step does what the step's sentences say for attempt 1, and carries on after any call that is interrupted, recording which calls were. (0108)
- **`When the hook "<hook>" of policy "<policy>" runs alone`**: the same for the hook, with a contributor lent by the contributions recorder and a hook reporter lent by the hook event reporter, acting on attempt 1 of the step the policy is attached to. (0108)
- **`When the input adapter "<adapter>" is called alone for the input "<input>" of step "<step>", with a data bag holding:`** followed by a table with the columns `key` and `value`: the runner builds a data bag of these values with its language's test support, and calls the adapter itself with the read access that data bag lends. (0108)
- **`And the step event reporter is failing`** and **`And the hook event reporter is failing`**: that recorder is made failing. (0108)
- **`Then the contributions recorder holds:`** followed by a table with the columns `key` and `value`, read with `read` by key, and exactly these keys, read with `keys`. (0108)
- **`Then the step event reporter kept the events:`** and **`Then the hook event reporter kept the events:`** followed by a table with the columns `level` (`info`, `warning` or `error`) and `message`, and optionally `data`, as JSON or `none` for an event without data: exactly these, in this order. (0108)
- **`Then the step event reporter kept nothing`** and **`Then the hook event reporter kept nothing`**: no event and no global metadata. (0108)
- **`Then the step event reporter kept the global metadata:`** followed by a table with the columns `key` and `value`: exactly these entries, in the order they were set; `value` is JSON. (0108)
- **`Then every call step "<step>" made to its step reporter was interrupted`** and **`Then every call the hook "<hook>" of policy "<policy>" made to its hook reporter was interrupted`** (0108)
- **`Then the call step "<step>" made setting "journey_id", and every call after it, was interrupted, and no call before it`** (0108)
- **`Then the input adapter returned <value>`** (0108)

Test mistakes, the values of `mistake` (0108):

- **`attempt left out`**: a scripted step does not describe an attempt it can have, named by its step and attempt.
- **`rescue step left out`**: a scripted step can fail on attempt 1 and its rescue step is not scripted, named by the rescue step.
- **`step left out`**: with `ensure all scripted`, a step is not scripted, named by its step.
- **`unknown step`**: the script names a step the workflow does not have, or the test reads the scripted run's record of one (0119).
- **`step scripted twice`**: the script names a step a second time.
- **`gap in the attempts`**: the script describes an attempt of a step before describing every attempt before it, named by its step and attempt.
- **`attempt scripted twice`**: the script chooses attempts of a step it has already described, named by its step and the first attempt it describes again: the number given, attempt 1 for `every`, and for `remaining` the attempt after the last one given by number, or attempt 1 when none was. (0119)
- **`no such attempt`**: the script chooses an attempt the step can never have, a number that is not a whole number from 1 or one past the most attempts the step can have, or `remaining` once the numbered attempts reach that most, named by its step and that attempt: the number given, or for `remaining` the attempt after the last one given by number. When a row's choice is both this and `attempt scripted twice` or `gap in the attempts`, only `no such attempt` is reported. (0119)
- **`rescue step skips`**: the script makes a rescue step skip.
- **`no contributor`** and **`no reporter`**: the script contributes for a step that declares no contributor, or emits or sets global metadata for one that declares no reporter.
- **`unknown provider`**: a fake is named after a provider the workflow does not have, named by its provider.
- **`another service`**: a fake makes another service than its provider makes, named by its provider. Used only in scenarios tagged `@fake-service-type`.

## Hook names

The hook names of proposal 0010: `on step success`, `on step failure`, `on step retry`, `on step abnormal termination`, `on workflow success`, `on workflow failure`. (0002; defined by 0010)

## Event names

The engine catalogue of proposal 0011 as amended by proposal 0040. Facts: `journey_started`, `attempt_started`, `input_adapter_supplied`, `input_adapter_failed`, `optional_input_absent`, `step_succeeded`, `step_failed`, `step_skipped`, `step_abnormal_termination`, `hook_called`, `contribution_committed`, `contributions_discarded`, `data_overwritten`, `journey_aborted`. Decisions: `step_retrying`, `step_given_up`, `step_rescuing`, `step_rescued`, `journey_succeeded`, `journey_failed`; and the events steps and hooks emit: `step_info`, `step_warning`, `step_error`, `journey_info`, `journey_warning`, `journey_error`. (0011, 0040, 0003)

Proposal 0095 adds the facts `service_provided` and `service_provider_failed`, and lets a service provider emit `journey_info`, `journey_warning` and `journey_error`. Proposal 0104 makes `service_provided` carry the implementation the provider made and the data it supplied. (0095, 0104)

Proposal 0102 adds the fact `global_metadata_set`. (0102)

## Abort reasons

The abort reasons of a journey's result (0009, 0032, 0042, 0054, 0056, 0058): `step could not be built`, `required data missing`, `wrong type`, `invalid lifecycle`, `policy could not be built`, `not a value`, `hook failed`, `reporter failed`, `rescue skipped` (0003), `reserved metadata key` (0102), and `unexpected result` (0122).

## Violation names

- **`hook defined twice`**: two policies attached to the same step, or to the same workflow, define the same hook. (0002)
- **`duplicate step name`**: two steps in one workflow have the same name. (0008)
- **`role not provided`**: a policy attached to the workflow requests a role the workflow does not provide. (0010)
- **`mode not accepted`**: a step, hook, service provider or reporter runs in an execution mode the executor does not accept. (0012, 0095)
- **`step adapted twice`**: two input adapters are attached to the same step, or one input adapter is attached to it more than once. (0060, 0116)
- **`duplicate adapter name`**: two input adapters of one workflow have the same name. (0116)
- **`input adapter for unknown step`**: an input adapter is attached to a step the workflow does not have. (0060)
- **`rescued step retried`**: a step has both a rescue step and a retry budget greater than 0. (0003)
- **`service not provided`**: a step requests a service that no provider serves for it. (0095)
- **`service requested twice`**: a step requests the same key twice among its services. (0095)
- **`service provided twice`**: two providers of one key are both attached to the same step, or both attached to no step, or one provider is attached to the same step more than once. (0095, 0116)
- **`duplicate provider name`**: two service providers of one workflow have the same name. (0095)
- **`service provider for unknown step`**: a service provider is attached to a step the workflow does not have. (0095)
- **`wrong service type`**: the provider serving a step supplies another type than the step requests for that key. (0095)
- **`attempt request in journey scope`**: a service provider of journey scope requests the name of the step being built or the attempt number. (0095)
