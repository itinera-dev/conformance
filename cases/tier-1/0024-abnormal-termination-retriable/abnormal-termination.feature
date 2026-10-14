@tier-1 @proposal-0024
Feature: Abnormal terminations are retried only when the step allows it
  Checks proposal 0024, which amends proposal 0008: whether an abnormal
  termination is retried is a setting of the step's descriptor; when it is off,
  the step fails at once. It never aborts the journey.
  Amended by proposal 0083: a failure carries its cause, a reason when one was
  written and an error when one ended the attempt.
  Amended by proposal 0106: the setting is `retry on abnormal termination`, on
  by default, so an abnormal termination is retried while the retry budget
  lasts, like a failure, unless the step turns it off.

  @proposal-0106
  Scenario: By default an abnormal termination is retried while the budget lasts, after its own hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And a step policy "watch" defines the hook "on step abnormal termination"
    And a step policy "watch" defines the hook "on step retry"
    And the hook "on step retry" of policy "watch" requests the retry cause
    And step "charge" has the policies "watch"
    When the workflow runs
    Then the events include, in order:
      | event                     | step   | attempt | policy | hook                         | cause                | decided by |
      | step_abnormal_termination | charge | 1       |        |                              |                      |            |
      | hook_called               | charge | 1       | watch  | on step abnormal termination |                      |            |
      | hook_called               | charge | 1       | watch  | on step retry                |                      |            |
      | step_retrying             | charge | 1       |        |                              | abnormal termination | default    |
      | attempt_started           | charge | 2       |        |                              |                      |            |
      | step_succeeded            | charge | 2       |        |                              |                      |            |
    And the hook "on step retry" of policy "watch" received the cause "abnormal termination"
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  @proposal-0106
  Scenario: An abnormal termination without a retry budget is given up with the cause "abnormal termination"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
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

  @proposal-0106
  Scenario: With retries of abnormal terminations turned off, an abnormal termination is not retried, even with a retry budget
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 2 retries
    And step "charge" does not retry abnormal terminations
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

  @proposal-0106
  Scenario: An abnormal termination that exhausts the budget fails with "retries exhausted"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
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

  @proposal-0083 @proposal-0106
  Scenario: When retries of abnormal terminations run out, the failure carries the last error and no reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
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

  @proposal-0083 @proposal-0106
  Scenario: The failure hook receives the last error when retries of abnormal terminations run out
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the error
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the hook "on step failure" of policy "alarm" received the error with the message "timeout"
    And the journey failed

  @proposal-0083 @proposal-0106
  Scenario: A required request for a failure reason that does not exist aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the failure reason
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the journey was aborted with the abort reason "required data missing"

  @proposal-0083 @proposal-0106
  Scenario: When the last attempt reported a failure, the exhausted retries carry its reason and no error
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code | message |
      | 1       | error   |      | timeout |
      | 2       | failure | busy |         |
    When the workflow runs
    Then the result's failure has the cause "retries exhausted"
    And the result's failure reason has the code "busy"
    And the result's failure carries no error
    And the journey failed

  @proposal-0083 @proposal-0106
  Scenario: An optional request for a failure reason after an abnormal termination is answered absent
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
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
