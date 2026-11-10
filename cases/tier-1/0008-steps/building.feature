@tier-1 @proposal-0008
Feature: Building a step
  Checks items 1 and 5 of proposal 0008 (Steps): a fresh step is built for
  every attempt, and a step that cannot be built aborts the journey without
  entering the retry loop.

  @proposal-0106
  Scenario: Every attempt gets a fresh step instance
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then step "charge" was built 2 times, each time as a new instance
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  Scenario: A step that cannot be built aborts the journey without retrying
    Given a step policy "policy" defines the hook "on step retry"
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" allows 3 retries
    And step "charge" cannot be built because its constructor fails with "no connection"
    When the workflow runs
    Then the hook "on step retry" of policy "policy" was not called
    And the journey was aborted
