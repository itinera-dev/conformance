@tier-1 @proposal-0003
Feature: The rescued step's hooks
  Checks proposal 0003 (Rescue steps): a failure handed to the rescue calls
  neither the retry hook nor the failure hook; the abnormal termination hook
  runs as usual, and may give the step up instead of rescuing it. A step that
  fails again after its rescue is given up under the ordinary rules.

  Scenario: The retry and failure hooks are not called for a rescued failure
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    And a step policy "watch" defines the hook "on step abnormal termination"
    And a step policy "watch" defines the hook "on step retry"
    And a step policy "watch" defines the hook "on step failure"
    And step "charge" has the policies "watch"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook                         |
      | watch  | on step abnormal termination |
    And the hook "on step retry" of policy "watch" was not called
    And the hook "on step failure" of policy "watch" was not called
    And the journey succeeded

  Scenario: FailWorkflow from the abnormal termination hook gives the step up instead of rescuing it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And step "charge_rescue" succeeds
    And a step policy "watch" defines the hook "on step abnormal termination"
    And the hook "on step abnormal termination" of policy "watch" returns FailWorkflow with code "stop"
    And step "charge" has the policies "watch"
    When the workflow runs
    Then the events are exactly:
      | event                     | step   | attempt | policy | hook                         | lifecycle    | cause        | decided by                          |
      | journey_started           |        |         |        |                              |              |              |                                     |
      | attempt_started           | charge | 1       |        |                              |              |              |                                     |
      | step_abnormal_termination | charge | 1       |        |                              |              |              |                                     |
      | hook_called               | charge | 1       | watch  | on step abnormal termination | FailWorkflow |              |                                     |
      | step_given_up             | charge | 1       |        |                              |              | FailWorkflow | watch, on step abnormal termination |
      | journey_failed            | charge |         |        |                              |              |              | watch, on step abnormal termination |
    And the result names the step "charge" whose hook failed the journey, with the code "stop"

  Scenario: A step that fails again after its rescue is given up, and is not rescued twice
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | expired  |
      | 2       | failure | declined |
    And step "charge_rescue" succeeds
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the failure cause
    And step "charge" has the policies "alarm"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | cause   |
      | step_rescuing  | charge | 1       | failure |
      | step_rescued   | charge | 1       |         |
      | step_failed    | charge | 2       |         |
      | step_given_up  | charge | 2       | failure |
      | journey_failed | charge |         | failure |
    And the hook "on step failure" of policy "alarm" was called 1 times
    And the hook "on step failure" of policy "alarm" received the cause "failure"
    And step "charge_rescue" was built 1 times, each time as a new instance
    And step "charge" ended as failed after 2 attempts
    And the result names the failed step "charge" with the code "declined"
