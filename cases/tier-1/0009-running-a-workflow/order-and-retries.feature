@tier-1 @proposal-0009
Feature: Order, the scan and retries
  Checks items 6 to 15 of proposal 0009 (Running a workflow): steps run in the
  order of their descriptors, data flows from earlier steps to later ones, a
  failed step ends the journey, and the retry budget is per step, explicit and
  0 by default, with attempts counted from 1.

  Scenario: Steps run in the order of their descriptors
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | reserve | success |
      | charge  | success |
      | ship    | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step    | key | attempt | code |
      | attempt_started | reserve |     | 1       |      |
      | attempt_started | charge  |     | 1       |      |
      | attempt_started | ship    |     | 1       |      |
    And the journey succeeded

  Scenario: A contribution from one step is an input to a later step
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge |                 | success |
      | ship   | receipt: string | success |
    And step "charge" contributes "receipt" = "R-1"
    When the workflow runs
    Then step "ship" was built with input "receipt" = "R-1"
    And the journey succeeded

  Scenario: A failed step ends the journey, and later steps do not run
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge |         |
      | ship   | success |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the steps ended as:
      | step   | status       | attempts |
      | charge | failed       | 1        |
      | ship   | not executed | 0        |
    And the journey failed

  @proposal-0106
  Scenario: Without a stated budget, a failure is not retried
    Given a step policy "policy" defines the hook "on step failure"
    Given the hook "on step failure" of policy "policy" requests the failure cause
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the cause "failure"
    And step "charge" ended as failed after 1 attempts
    And the journey failed

  @proposal-0106
  Scenario: With a budget of N retries, a step is attempted at most N plus 1 times
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    When the workflow runs
    Then step "charge" ended as failed after 3 attempts
    And the events include, in order:
      | event           | step   | key | attempt | code |
      | attempt_started | charge |     | 1       |      |
      | attempt_started | charge |     | 2       |      |
      | attempt_started | charge |     | 3       |      |
    And the journey failed
