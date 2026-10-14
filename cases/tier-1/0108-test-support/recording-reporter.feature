@tier-1 @proposal-0108 @capability-testing
Feature: The recording reporter keeps the journey
  Checks proposal 0108 (Test support): the recording reporter keeps every event
  it receives, in order, and the latest value of each entry of global metadata.

  Scenario: The recording reporter keeps every event in order
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
      | 2       | success |          |
    And step "charge" allows 1 retries
    And step "ship" emits step_info "shipping"
    And step "ship" succeeds
    And the workflow lists the reporters "audit"
    And the executor uses its default dispatcher
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the recording reporter of test support kept the same events as the reporter "audit"

  Scenario: The recording reporter keeps the latest value of each entry of global metadata
    Given a workflow "orders" with the steps:
      | step   |
      | lookup |
      | charge |
    And step "lookup" sets the global metadata "user_id" to "u-7"
    And step "lookup" succeeds
    And step "charge" sets the global metadata "user_id" to "u-8"
    And step "charge" succeeds
    And the workflow's ID generator returns "order-42"
    And the workflow instance is created with the global metadata:
      | key    | value  |
      | tenant | "acme" |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the recording reporter of test support kept the global metadata:
      | key        | value      |
      | journey_id | "order-42" |
      | tenant     | "acme"     |
      | user_id    | "u-8"      |
