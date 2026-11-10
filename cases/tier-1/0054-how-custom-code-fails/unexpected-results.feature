@tier-1 @proposal-0054
Feature: Custom code that returns an unexpected result
  Checks proposal 0122, which amends proposals 0054, 0010 and 0009: when the
  executor waits for a result and custom code returns something that is not one
  of the results its call can return, such as a null-like value, the journey is
  aborted with "unexpected result", naming the code, and nothing is retried.
  Before a journey, run is refused. A call whose result is always nothing, such
  as a workflow hook, is void: what it returns is never read. An asynchronous
  call is awaited, and its result is what it resolves to. A language whose
  types rule out an unexpected result makes it impossible to express, and
  claims the tag unexpected-result as impossible.
  Amended by proposal 0134: the ordered pass starts with the fact
  `pass_started`, right after `journey_started`.

  @proposal-0122 @unexpected-result
  Scenario: A step that returns no outcome aborts the journey and is not retried
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge |         |
      | ship   | success |
    And step "charge" allows 2 retries
    And step "charge" returns no outcome
    When the workflow runs
    Then the events include, in order:
      | event           | step   | code              |
      | attempt_started | charge |                   |
      | journey_aborted | charge | unexpected result |
    And the last event is "journey_aborted"
    And the steps ended as:
      | step   | status       | attempts |
      | charge | aborted      | 1        |
      | ship   | not executed | 0        |
    And the result names the step "charge" as where the journey was aborted, with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result
  Scenario: A rescue step that returns no outcome aborts the journey
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And step "charge_rescue" returns no outcome
    When the workflow runs
    Then the events include, in order:
      | event           | step          | code              |
      | journey_aborted | charge_rescue | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"
    And the steps ended as:
      | step          | status  |
      | charge        | aborted |
      | charge_rescue | aborted |

  @proposal-0122 @unexpected-result
  Scenario: A step hook that returns something that is not a lifecycle aborts the journey
    Given a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" returns something that is not a lifecycle
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook            | code              |
      | journey_aborted | charge | audit  | on step success | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result
  Scenario: A step hook that returns a null-like value does not keep the default
    Given a step policy "audit" defines the hook "on step failure"
    And the hook "on step failure" of policy "audit" returns a null-like value
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | audit    |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook            | code              |
      | journey_aborted | charge | audit  | on step failure | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result @proposal-0134
  Scenario: An input adapter that returns no result aborts the journey
    Given the input adapter "pricing" returns no result for "amount"
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And step "charge" requests optional input "amount" of type integer
    When the workflow runs
    Then the events are exactly:
      | event           | step   | attempt | adapter | key    | code              |
      | journey_started |        |         |         |        |                   |
      | pass_started    |        |         |         |        |                   |
      | attempt_started | charge | 1       |         |        |                   |
      | journey_aborted | charge |         | pricing | amount | unexpected result |
    And step "charge" ended as aborted
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122
  Scenario: An input adapter that returns the value null supplies it, and it is checked against the input's type
    Given the input adapter "pricing" returns null when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | adapter | key    | code       |
      | input_adapter_supplied | charge | pricing |        |            |
      | journey_aborted        | charge | pricing | amount | wrong type |
    And the journey was aborted with the abort reason "wrong type"

  @proposal-0122 @unexpected-result @proposal-0134
  Scenario: A service provider that returns a null-like value aborts the journey
    Given the service provider "warehouse" makes a labeller for "stock", for each attempt
    And the service provider "warehouse" returns a null-like value
    Given a workflow "orders" with the steps:
      | step   | services        | outcome |
      | charge | stock: labeller | success |
    And the workflow binds the service provider "warehouse"
    When the workflow runs
    Then the events are exactly:
      | event           | step   | attempt | provider  | key   | code              |
      | journey_started |        |         |           |       |                   |
      | pass_started    |        |         |           |       |                   |
      | attempt_started | charge | 1       |           |       |                   |
      | journey_aborted | charge |         | warehouse | stock | unexpected result |
    And step "charge" ended as aborted
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result
  Scenario: A step whose construction returns no step aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" is built as a null-like value
    When the workflow runs
    Then the events include, in order:
      | event           | step   | code              |
      | journey_aborted | charge | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result
  Scenario: A step policy whose construction returns no policy aborts the journey
    Given a step policy "audit" defines the hook "on step success"
    And the policy "audit" is built as a null-like value
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | code              |
      | journey_aborted | charge | audit  | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @unexpected-result
  Scenario: A workflow policy whose construction returns no policy refuses run
    Given a workflow policy "closing" defines the hook "on workflow success"
    And the policy "closing" is built as a null-like value
    Given a workflow "orders" with the policies "closing" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then run was refused
    And no event was emitted
    And no step ran

  @proposal-0122
  Scenario: What a workflow hook returns is never read
    Given a workflow policy "closing" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "closing" returns a value
    Given a workflow "orders" with the policies "closing" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then the hook "on workflow success" of policy "closing" was called 1 times
    And the journey succeeded

  @proposal-0122 @capability-async @unexpected-result
  Scenario: An asynchronous step that resolves to no outcome aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" is asynchronous
    And step "charge" returns no outcome
    When the workflow runs
    Then the events include, in order:
      | event           | step   | code              |
      | journey_aborted | charge | unexpected result |
    And the journey was aborted with the abort reason "unexpected result"

  @proposal-0122 @capability-async
  Scenario: An asynchronous workflow hook is awaited, and its failure aborts the journey
    Given the workflow policies and their hooks:
      | policy  | hook                | fails with    |
      | closing | on workflow success | ledger closed |
    And the hook "on workflow success" of policy "closing" is asynchronous
    Given a workflow "orders" with the policies "closing" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"
    And the result's abort carries the error "ledger closed"

  @proposal-0122 @capability-async
  Scenario: What an asynchronous workflow hook resolves to is never read
    Given a workflow policy "closing" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "closing" is asynchronous
    And the hook "on workflow success" of policy "closing" returns a value
    Given a workflow "orders" with the policies "closing" and the steps:
      | step   | outcome |
      | charge | success |
    When the workflow runs
    Then the hook "on workflow success" of policy "closing" was called 1 times
    And the journey succeeded
