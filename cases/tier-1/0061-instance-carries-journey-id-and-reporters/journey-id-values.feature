@tier-1 @proposal-0061
Feature: A journey ID is a string that is not empty
  Checks proposal 0122, which amends proposal 0009 as amended by proposal 0061:
  the journey ID is a string that is not empty. An ID generator that produces
  anything else, such as a null-like value, a number or an empty string, makes
  creating the workflow instance fail, so there is no journey and no event.

  @proposal-0122 @non-string-journey-id
  Scenario: An ID generator that returns something that is not a string fails the instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns something that is not a string
    When the workflow runs
    Then creating the workflow instance failed
    And no event was emitted
    And no step ran

  @proposal-0122 @empty-journey-id
  Scenario: An ID generator that returns an empty string fails the instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow's ID generator returns ""
    When the workflow runs
    Then creating the workflow instance failed
    And no event was emitted
    And no step ran
