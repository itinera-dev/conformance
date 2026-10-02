@tier-1 @proposal-0011
Feature: Reporters and dispatchers
  Checks points 1 to 7 of proposal 0011 (Events): the workflow lists its
  reporters, the executor owns the dispatcher and adds them to it, a dispatcher
  can be given to the executor, and a reporter that throws aborts the journey.

  Scenario: With the default dispatcher, every reporter the workflow lists receives the same events
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit", "metrics"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporters "audit", "metrics" received the same events
    And the reporter "audit" received the event "journey_succeeded"

  Scenario: A dispatcher given to the executor is used, and the workflow's reporters are added to it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit"
    And the executor is given a dispatcher holding the reporter "test"
    When the workflow runs
    Then the reporters "test", "audit" received the same events

  Scenario: A given dispatcher that ignores added reporters delivers only to its own
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit"
    And the executor is given a dispatcher holding the reporter "test" that ignores added reporters
    When the workflow runs
    Then the reporter "test" received the event "journey_succeeded"
    And the reporter "audit" received no event

  Scenario: A reporter that throws aborts the journey, and the others still receive journey_aborted
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "broken", "audit"
    And the reporter "broken" throws
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the event "journey_aborted"
    And the journey was aborted
