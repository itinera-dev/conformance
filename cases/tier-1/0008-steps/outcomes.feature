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
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
      | 2       | success |
    And a step policy "policy" defines the hook "on step abnormal termination"
    And the hook "on step abnormal termination" of policy "policy" requests the error
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step abnormal termination" of policy "policy" received an error
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  @proposal-0106
  Scenario: A failure without a retry budget fails the journey on its first attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And step "ship" succeeds
    When the workflow runs
    Then step "charge" ended as failed after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the journey failed

  @proposal-0106
  Scenario: A failure is tried again while the retry budget lasts
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | success |             |
    And a step policy "policy" defines the hook "on step retry"
    And the hook "on step retry" of policy "policy" requests the retry cause
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step retry" of policy "policy" received the cause "failure"
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  Scenario: The failure hook receives the reason the step gave
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     | message           | details               |
      | 1       | failure | declined | card was declined | {"bank_code": "05"}   |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" requests the failure reason
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the failure reason with code "declined", message "card was declined" and details {"bank_code": "05"}
    And the journey failed

  @proposal-0106
  Scenario: When retries run out, the failure hook is called with the cause "retries exhausted"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" requests the failure cause
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the cause "retries exhausted"
    And step "charge" ended as failed after 3 attempts
    And the journey failed
