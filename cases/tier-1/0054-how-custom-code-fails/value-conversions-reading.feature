@tier-1 @proposal-0054 @capability-value-conversions
Feature: A value conversion that fails while a value is read
  Checks proposal 0113, which amends proposal 0054: in a language whose
  applications supply value conversions, a conversion that fails, or a check
  that refuses a value, while a request reads it means the value has the wrong
  type. The journey is aborted with "wrong type", naming whom a value of the
  wrong type names. An abort caused by a check that refuses a value carries
  no error; one caused by a conversion that throws or returns an error may
  carry it, which these cases do not check. A read through an input
  adapter's access to the data bag is reported to the adapter as another type,
  and nothing is emitted. Only a language that claims the capability
  value-conversions runs these cases.

  @proposal-0113
  Scenario: A step input whose conversion fails aborts the journey with "wrong type"
    Given a workflow "orders" with the steps:
      | step   | inputs                 | outcome |
      | charge | order: throwing record | success |
    And the data bag contains:
      | key   | value     |
      | order | {"id": 7} |
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key   | code       |
      | attempt_started | charge |       |            |
      | journey_aborted | charge | order | wrong type |
    And no step ran
    And step "charge" ended as aborted after 1 attempts

  @proposal-0113
  Scenario: A step input whose check refuses the value aborts the journey with "wrong type" and no error
    Given a workflow "orders" with the steps:
      | step   | inputs                 | outcome |
      | charge | order: rejected record | success |
    And the data bag contains:
      | key   | value     |
      | order | {"id": 7} |
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key   | code       |
      | journey_aborted | charge | order | wrong type |
    And the result's abort carries no error
    And no step ran
    And step "charge" ended as aborted after 1 attempts

  @proposal-0113
  Scenario: A step input that an input adapter supplies, whose conversion fails, aborts with "wrong type" naming the adapter
    Given the input adapter "pricing" returns {"id": 7} when step "charge" requests "order"
    Given a workflow "orders" with the steps:
      | step   | inputs                 | outcome |
      | charge | order: throwing record | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event                  | step   | key   | adapter | code       |
      | input_adapter_supplied | charge | order | pricing |            |
      | journey_aborted        | charge | order | pricing | wrong type |
    And no step ran

  @proposal-0113
  Scenario: A hook's data from the workflow whose conversion fails aborts the journey before the hook runs
    Given a step policy "audit" defines the hook "on step success"
    Given the hook "on step success" of policy "audit" requests data from the workflow "order" of type throwing record
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    And the data bag contains:
      | key   | value     |
      | order | {"id": 7} |
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key   | policy | hook            | code       |
      | step_succeeded  | charge |       |        |                 |            |
      | journey_aborted | charge | order | audit  | on step success | wrong type |
    And the hook "on step success" of policy "audit" was called 0 times

  @proposal-0113
  Scenario: A hook's data from the step whose check refuses the value aborts the journey before the hook runs
    Given a step policy "audit" defines the hook "on step success"
    Given the hook "on step success" of policy "audit" requests optional step data "order" of type rejected record
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | audit    | success |
    And step "charge" contributes "order" = {"id": 7}
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key   | policy | hook            | code       |
      | step_succeeded  | charge |       |        |                 |            |
      | journey_aborted | charge | order | audit  | on step success | wrong type |
    And the hook "on step success" of policy "audit" was called 0 times
    And the result's abort carries no error

  @proposal-0113
  Scenario: A rescue step's data from the step it rescues whose check refuses the value aborts the journey
    Given a workflow "orders" with the steps:
      | step   | rescue |
      | charge | yes    |
    And step "charge" attempts:
      | attempt | outcome | code    | contributes          |
      | 1       | failure | expired | {"order": {"id": 7}} |
      | 2       | success |         |                      |
    And step "charge_rescue" requests rescued step data "order" of type rejected record
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the result names the step "charge_rescue" as where the journey was aborted, with the abort reason "wrong type"
    And the events include, in order:
      | event           | step          | key   | code       |
      | attempt_started | charge_rescue |       |            |
      | journey_aborted | charge_rescue | order | wrong type |
    And the result's abort carries no error
    And step "charge" ended as aborted

  @proposal-0113
  Scenario: An input adapter's request whose conversion fails aborts the journey before the adapter is called
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    And the input adapter "pricing" requests data from the workflow "order" of type throwing record
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag contains:
      | key   | value     |
      | order | {"id": 7} |
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key   | adapter | code       |
      | journey_aborted | charge | order | pricing | wrong type |
    And no step ran

  @proposal-0113
  Scenario: A service provider's request whose check refuses the value aborts the journey before the provider is called
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" requests data from the workflow "gateway" of type rejected record
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    And the data bag contains:
      | key     | value              |
      | gateway | {"name": "stripe"} |
    When the workflow runs
    Then the journey was aborted with the abort reason "wrong type"
    And the events include, in order:
      | event           | step   | key     | provider | code       |
      | journey_aborted | charge | gateway | payments | wrong type |
    And the result's abort carries no error
    And the service provider "payments" was called 0 times
    And no step ran

  @proposal-0113
  Scenario: A read through an input adapter's access whose conversion fails is another type, and emits nothing
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the input adapter "pricing" requests the data bag
    And the input adapter "pricing" returns "price.charge" of type throwing record, read from the data bag, for "amount"
    And the data bag contains:
      | key          | value     |
      | amount       | 42        |
      | price.charge | {"id": 7} |
    When the workflow runs
    Then step "charge" was built with input "amount" = 42
    And the events are exactly:
      | event             | step   | attempt |
      | journey_started   |        |         |
      | attempt_started   | charge | 1       |
      | step_succeeded    | charge | 1       |
      | journey_succeeded |        |         |
    And the journey succeeded
