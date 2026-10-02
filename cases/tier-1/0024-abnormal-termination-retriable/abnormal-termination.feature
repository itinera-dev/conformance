@tier-1 @proposal-0024
Feature: Abnormal terminations are retried only when the step allows it
  Checks proposal 0024, which amends proposal 0008: an abnormal termination is
  retried only when the step's descriptor marks it retriable; otherwise the step
  fails at once. It never aborts the journey.

  Scenario: By default an abnormal termination is not retried, even with a retry budget
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" requests the failure cause
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the cause "abnormal termination"
    And step "charge" ended as failed after 1 attempts
    And the journey failed

  Scenario: A retriable abnormal termination that exhausts the budget fails with "retries exhausted"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" requests the failure cause
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the hook "on step failure" of policy "policy" received the cause "retries exhausted"
    And step "charge" ended as failed after 2 attempts
    And the journey failed
