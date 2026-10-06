@tier-1 @proposal-0011
Feature: Reporters and dispatchers
  Checks points 1 to 7 of proposal 0011 (Events): the workflow lists its
  reporters, the executor owns the dispatcher and adds them to it, a dispatcher
  can be given to the executor, and a reporter that throws aborts the journey.
  Amended by proposal 0081: delivery of the event a reporter failed on stops at
  that reporter, and every other reporter receives journey_aborted.

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

  @spec-defect-0047 @proposal-0081
  Scenario: The event a reporter failed on does not reach the reporters after it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "broken", "audit"
    And the reporter "broken" throws on "journey_started"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" did not receive the event "journey_started"
    And the reporter "audit" received the event "journey_aborted"
    And the reporter "broken" did not receive the event "journey_aborted"
    And the journey was aborted with the abort reason "reporter failed"

  @proposal-0081
  Scenario: Delivery of an engine event stops at the reporter that failed, and every other reporter receives journey_aborted
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit", "fragile", "metrics"
    And the reporter "fragile" throws on "attempt_started"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the event "attempt_started"
    And the reporter "metrics" did not receive the event "attempt_started"
    And the reporter "audit" received the event "journey_aborted"
    And the reporter "metrics" received the event "journey_aborted"
    And the reporter "fragile" did not receive the event "journey_aborted"
    And the journey was aborted with the abort reason "reporter failed"

  @proposal-0081
  Scenario: Delivery of an event a step emitted stops at the reporter that failed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" emits step_info "progress"
    And step "charge" succeeds
    And the workflow lists the reporters "audit", "fragile", "metrics"
    And the reporter "fragile" throws on "step_info"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the reporter "audit" received the event "step_info"
    And the reporter "metrics" did not receive the event "step_info"
    And the reporter "audit" received the event "journey_aborted"
    And the reporter "metrics" received the event "journey_aborted"
    And the reporter "fragile" did not receive the event "journey_aborted"
    And the journey was aborted with the abort reason "reporter failed"
