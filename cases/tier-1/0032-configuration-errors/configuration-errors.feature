@tier-1 @proposal-0032
Feature: Configuration errors
  Checks proposal 0032, which amends proposal 0009, as amended by proposal 0042:
  an error in how a workflow is put together is refused before any journey, with
  no event; a configuration error found while the journey runs aborts it, the
  events already emitted remain, and journey_aborted is the last event.
  Amended by proposal 0083: an abort no error caused carries no error.

  Scenario: A configuration error found partway through a journey ends the stream with journey_aborted
    Given a workflow "orders" with the steps:
      | step    | inputs          | outcome |
      | reserve |                 | success |
      | charge  |                 | success |
      | ship    | address: string | success |
    And the data bag is empty
    When the workflow runs
    Then the events include, in order:
      | event             | step    | key     | attempt | code                  |
      | journey_started   |         |         |         |                       |
      | step_succeeded    | reserve |         | 1       |                       |
      | step_succeeded    | charge  |         | 1       |                       |
      | journey_aborted   | ship    | address |         | required data missing |
    And the last event is "journey_aborted"
    And the steps ended as:
      | step    | status    | attempts |
      | reserve | succeeded | 1        |
      | charge  | succeeded | 1        |
    And the journey was aborted

  @proposal-0042
  Scenario: A configuration error in how the workflow is put together is refused before any journey, with no event
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

  @proposal-0083
  Scenario: An abort that no error caused carries no error
    Given a workflow "orders" with the steps:
      | step | inputs          | outcome |
      | ship | address: string | success |
    And the data bag is empty
    When the workflow runs
    Then the journey was aborted with the abort reason "required data missing"
    And the result's abort carries no error
