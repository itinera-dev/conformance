@tier-1 @proposal-0054 @capability-value-conversions
Feature: A value conversion that fails while a value is captured
  Checks proposal 0113, which amends proposal 0054: in a language whose
  applications supply value conversions, a conversion that fails while one of
  the application's objects is captured as a value means what was captured is
  not a value. A contribution, event data, global metadata, a reason's details
  or a service provider's data abort the journey with "not a value", and an
  input adapter's supply aborts it with "step could not be built", naming whom
  they name for something that is not a value. Either abort may carry the
  conversion's error, which these cases do not check. Only a language that
  claims the capability value-conversions runs these cases.

  @proposal-0113
  Scenario: A contribution whose conversion fails aborts the journey with "not a value"
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" contributes a throwing record as "order"
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the events include, in order:
      | event           | step   | key   | code        |
      | journey_aborted | charge | order | not a value |
    And no contribution of "order" was committed

  @proposal-0113
  Scenario: Event data whose conversion fails aborts the journey, and the event is not delivered
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" emits step_info "order checked" with a throwing record as data
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And no event carries the message "order checked"

  @proposal-0113
  Scenario: Global metadata whose conversion fails aborts the journey and reaches no reporter
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | lookup | success |
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And step "lookup" sets the global metadata "customer" to a throwing record
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the reporter "audit" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |
    And the events include, in order:
      | event           | step   | attempt | key      | code        |
      | attempt_started | lookup | 1       |          |             |
      | journey_aborted | lookup |         | customer | not a value |
    And the reporter "audit" did not receive the event "global_metadata_set"

  @proposal-0113
  Scenario: A reason whose details fail to convert aborts the journey with "not a value"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" fails with code "declined" and a throwing record as details
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"

  @proposal-0113
  Scenario: A service provider's data whose conversion fails aborts the journey, and no service event follows
    Given the service provider "payments" makes a labeller for "payments", for each attempt
    And the service provider "payments" supplies a throwing record as data with each instance
    Given a workflow "orders" with the steps:
      | step   | services           | outcome |
      | charge | payments: labeller | success |
    And the workflow binds the service provider "payments"
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the events are exactly:
      | event           | step   | attempt | provider | code        |
      | journey_started |        |         |          |             |
      | attempt_started | charge | 1       |          |             |
      | journey_aborted | charge |         | payments | not a value |
    And no step ran

  @proposal-0113
  Scenario: An input adapter's supply whose conversion fails aborts with "step could not be built"
    Given a workflow "orders" with the steps:
      | step   | inputs                 | outcome |
      | charge | order: throwing record | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the input adapter "pricing" returns a throwing record for "order"
    When the workflow runs
    Then the journey was aborted with the abort reason "step could not be built"
    And the events include, in order:
      | event                | step   | key   | adapter | code                    |
      | input_adapter_failed | charge | order | pricing |                         |
      | journey_aborted      | charge |       |         | step could not be built |
    And no step ran
