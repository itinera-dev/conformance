@tier-1 @proposal-0008
Feature: Outcomes of running a step
  Checks items 6 to 11 of proposal 0008 (Steps): an error escaping a running
  step is an abnormal termination; failures carry a reason; exhausted retries
  reach the failure hook. Amended by proposal 0024, then by proposal 0106: a
  failure carries no retriable flag, and a failure or an abnormal termination is
  tried again while the retry budget lasts, unless the step's descriptor turns
  off retries of abnormal terminations.

  @proposal-0106
  Scenario: An error escaping a running step is an abnormal termination, retried while the budget lasts
    Given a step policy "policy" defines the hook "on step abnormal termination"
    Given the hook "on step abnormal termination" of policy "policy" requests the error
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
      | 2       | success |
    When the workflow runs
    Then the hook "on step abnormal termination" of policy "policy" received an error
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  @proposal-0106
  Scenario: A failure without a retry budget fails the journey on its first attempt
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
  Scenario: A failure is tried again while the retry budget lasts
    Given a step policy "policy" defines the hook "on step retry"
    Given the hook "on step retry" of policy "policy" requests the retry cause
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    When the workflow runs
    Then the hook "on step retry" of policy "policy" received the cause "failure"
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  Scenario: The failure hook receives the reason the step gave
    Given a step policy "policy" defines the hook "on step failure"
    Given the hook "on step failure" of policy "policy" requests the failure reason
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" attempts:
      | attempt | outcome | code     | message           | details               |
      | 1       | failure | declined | card was declined | {"bank_code": "05"}   |
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the failure reason with code "declined", message "card was declined" and details {"bank_code": "05"}
    And the journey failed

  @proposal-0106
  Scenario: When retries run out, the failure hook is called with the cause "retries exhausted"
    Given a step policy "policy" defines the hook "on step failure"
    Given the hook "on step failure" of policy "policy" requests the failure cause
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the cause "retries exhausted"
    And step "charge" ended as failed after 3 attempts
    And the journey failed
