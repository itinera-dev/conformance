@tier-1 @proposal-0032
Feature: Configuration errors
  Checks proposal 0032, which amends proposal 0009: a configuration error caught
  when the workflow is built produces no journey and no event; one found while
  the journey runs aborts it, the events already emitted remain, and
  journey_aborted is the last event.

  Scenario: A configuration error found partway through a journey ends the stream with journey_aborted
    Given a workflow "orders" with the steps:
      | step    |
      | reserve |
      | charge  |
      | ship    |
    And step "reserve" succeeds
    And step "charge" succeeds
    And step "ship" requests input "address" of type string
    And step "ship" succeeds
    And the data bag is empty
    When the workflow runs
    Then the events include, in order:
      | event             | step    | key     | attempt | code                  |
      | journey_started   |         |         |         |                       |
      | step_succeeded    | reserve |         | 1       |                       |
      | step_succeeded    | charge  |         | 1       |                       |
      | journey_aborted   | ship    | address |         | required data missing |
    And the last event is "journey_aborted"
    And step "reserve" ended as succeeded after 1 attempts
    And step "charge" ended as succeeded after 1 attempts
    And the journey was aborted

  @capability-build-time-configuration-check
  Scenario: A configuration error caught when the workflow is built produces no event
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | charge |
    And step "charge" succeeds
    When the workflow runs
    Then admission is refused with the violations:
      | violation           |
      | duplicate step name |
    And no event was emitted
    And no journey ID was produced

  @capability-run-time-configuration-check
  Scenario: A configuration error found only when the journey runs aborts it with "invalid configuration"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | charge |
    And step "charge" succeeds
    When the workflow runs
    Then the journey was aborted with the abort reason "invalid configuration", listing the violations:
      | violation           |
      | duplicate step name |
    And the last event is "journey_aborted"
    And no step ran
