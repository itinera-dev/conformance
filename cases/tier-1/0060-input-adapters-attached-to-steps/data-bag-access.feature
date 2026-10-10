@tier-1 @proposal-0060
Feature: Input adapters that read the data bag
  Checks proposal 0091, which amends proposal 0060: an input adapter may request
  read access to the data bag. Its reads are its own: a missing key or a value of
  another type emits nothing and aborts nothing. It sees what earlier attempts
  committed, never writes the data bag, and its access shows nothing after its
  call.

  @proposal-0091
  Scenario: An adapter reads a key computed for the step and supplies its value
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key          | value |
      | amount       | 42    |
      | price.charge | 7     |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "price.charge" of type integer, read from the data bag, for "amount"
    When the workflow runs
    Then step "charge" was built with input "amount" = 7
    And the events include, in order:
      | event                  | step   | key    | adapter |
      | input_adapter_supplied | charge | amount | pricing |
    And the journey succeeded

  @proposal-0091
  Scenario: A read of a missing key emits nothing, and the input comes from the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "price.charge" of type integer, read from the data bag, for "amount"
    When the workflow runs
    Then step "charge" was built with input "amount" = 42
    And the events are exactly:
      | event             | step   | attempt |
      | journey_started   |        |         |
      | attempt_started   | charge | 1       |
      | step_succeeded    | charge | 1       |
      | journey_succeeded |        |         |

  @proposal-0091
  Scenario: A read of another type aborts nothing, and the input comes from the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key          | value   |
      | amount       | 42      |
      | price.charge | "seven" |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "price.charge" of type integer, read from the data bag, for "amount"
    When the workflow runs
    Then step "charge" was built with input "amount" = 42
    And the journey succeeded

  @proposal-0091
  Scenario: An adapter sees what an earlier attempt's retry hook contributed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And a step policy "watch" defines the hook "on step retry"
    And the hook "on step retry" of policy "watch" contributes "bonus" = 5
    And step "charge" has the policies "watch"
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "bonus" of type integer, read from the data bag, for "amount"
    When the workflow runs
    Then step "charge" was built for attempt 1 with input "amount" = 42
    And step "charge" was built for attempt 2 with input "amount" = 5
    And the journey succeeded

  @proposal-0091
  Scenario: An adapter does not see what a failed earlier attempt contributed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        | contributes           |
      | 1       | retriable failure | unreachable | {"price.charge": 1}   |
      | 2       | success           |             |                       |
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "price.charge" of type integer, read from the data bag, for "amount"
    When the workflow runs
    Then step "charge" was built for attempt 2 with input "amount" = 42
    And the journey succeeded

  @proposal-0091 @bag-write
  Scenario: An adapter that writes through its access leaves the data bag unchanged
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And step "ship" requests input "amount" of type integer
    And step "ship" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" writes "amount" = 0 through its data bag access
    When the workflow runs
    Then step "ship" was built with input "amount" = 42
    And the result's data bag contains:
      | key    | value |
      | amount | 42    |

  @proposal-0091 @late-handle
  Scenario: An adapter's access kept from an earlier call shows nothing later
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" requests input "amount" of type integer
    And step "charge" contributes "price" = 5
    And step "charge" succeeds
    And step "ship" requests input "amount" of type integer
    And step "ship" succeeds
    And the data bag contains:
      | key    | value |
      | amount | 1     |
    And the workflow declares the input adapter "pricing" for the steps "charge", "ship"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" keeps its data bag access when called for step "charge", and returns "price" of type integer, read through that kept access, for "amount" when called for step "ship"
    When the workflow runs
    Then step "ship" was built with input "amount" = 1
