@tier-1 @proposal-0024
Feature: Abnormal terminations are retried only when the step allows it
  Checks proposal 0024, which amends proposal 0008: an abnormal termination is
  retried only when the step's descriptor marks it retriable; otherwise the step
  fails at once. It never aborts the journey.
  Amended by proposal 0083: a failure carries its cause, a reason when one was
  written and an error when one ended the attempt.

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

  @proposal-0083
  Scenario: When retries of abnormal terminations run out, the failure carries the last error and no reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    When the workflow runs
    Then the events include, in order:
      | event          | step   | cause             | error   |
      | journey_failed | charge | retries exhausted | timeout |
    And the result's failure has the cause "retries exhausted"
    And the result's failure carries the error "timeout"
    And the result's failure carries no reason
    And the journey failed

  @proposal-0083
  Scenario: The failure hook receives the last error when retries of abnormal terminations run out
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the error
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the hook "on step failure" of policy "alarm" received the error with the message "timeout"
    And the journey failed

  @proposal-0083
  Scenario: A required request for a failure reason that does not exist aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the failure reason
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the journey was aborted with the abort reason "required data missing"

  @proposal-0083
  Scenario: When the last attempt reported a failure, the exhausted retries carry its reason and no error
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome           | code | message |
      | 1       | error             |      | timeout |
      | 2       | retriable failure | busy |         |
    When the workflow runs
    Then the result's failure has the cause "retries exhausted"
    And the result's failure reason has the code "busy"
    And the result's failure carries no error
    And the journey failed

  @proposal-0083
  Scenario: An optional request for a failure reason after an abnormal termination is answered absent
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And the abnormal termination of step "charge" is retriable
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And a step policy "watch" defines the hook "on step retry"
    And the hook "on step retry" of policy "watch" requests the optional failure reason
    And step "charge" has the policies "watch"
    When the workflow runs
    Then the hook "on step retry" of policy "watch" received no failure reason
    And the journey succeeded
