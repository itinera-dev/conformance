@tier-1 @proposal-0102
Feature: Global metadata that cannot be set
  Checks proposal 0102 (Global metadata): an entry that is not a value, or that
  sets the reserved key journey_id, aborts the journey when set while it runs
  and is refused by run when it is initial global metadata; a reporter that
  fails on an entry aborts the journey, or, on an entry set before the journey
  starts, makes run refuse it.

  @non-value
  Scenario: A step's entry that is not a value aborts the journey with "not a value" and reaches no reporter
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
    And step "lookup" sets the global metadata "callback" to a non-value
    And step "lookup" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "not a value"
    And the reporter "audit" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |
    And the events include, in order:
      | event           | step   | attempt | key      | code        |
      | attempt_started | lookup | 1       |          |             |
      | journey_aborted | lookup |         | callback | not a value |
    And the reporter "audit" did not receive the event "global_metadata_set"
    And step "lookup" ended as aborted

  @non-value
  Scenario: Initial global metadata that is not a value is refused by run
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow instance is created with a non-value as global metadata "callback"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: A step that sets the journey ID aborts the journey with "reserved metadata key"
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
    And step "lookup" sets the global metadata "journey_id" to "forged"
    And step "lookup" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "reserved metadata key"
    And the reporter "audit" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |
    And the events include, in order:
      | event           | step   | attempt | key        | code                  |
      | attempt_started | lookup | 1       |            |                       |
      | journey_aborted | lookup |         | journey_id | reserved metadata key |
    And the reporter "audit" did not receive the event "global_metadata_set"
    And step "lookup" ended as aborted

  Scenario: Initial global metadata that sets the journey ID is refused by run
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow instance is created with the global metadata:
      | key        | value    |
      | journey_id | "forged" |
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    When the workflow runs
    Then run was refused
    And no event was emitted

  Scenario: A reporter that fails on an entry aborts the journey, and the reporters after it do not receive the entry
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow lists the reporters "audit", "fragile", "metrics"
    And the reporter "fragile" fails when it receives the global metadata "user_id"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And the reporter "audit" received the global metadata:
      | key        | value      | after           |
      | journey_id | "order-42" | none            |
      | user_id    | "u-7"      | attempt_started |
    And the reporter "metrics" received the global metadata:
      | key        | value      | after |
      | journey_id | "order-42" | none  |
    And the reporter "audit" did not receive the event "global_metadata_set"
    And the reporter "metrics" received the event "journey_aborted"
    And the reporter "fragile" did not receive the event "journey_aborted"
    And step "lookup" ended as aborted

  Scenario: A reporter that fails on the journey ID makes run refuse the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit", "fragile"
    And the reporter "fragile" fails when it receives the global metadata "journey_id"
    And the executor uses its default dispatcher
    When the workflow runs
    Then run was refused
    And no event was emitted
