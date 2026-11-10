@tier-1 @proposal-0003
Feature: The rescued step's hooks
  Checks proposal 0003 (Rescue steps): a failure handed to the rescue calls
  neither the retry hook nor the failure hook; the abnormal termination hook
  runs as usual, and may give the step up instead of rescuing it. A step that
  fails again after its rescue is given up under the ordinary rules.
  Amended by proposal 0134: the ordered pass starts with the fact
  `pass_started`, right after `journey_started`.

  Scenario: The retry and failure hooks are not called for a rescued failure
    Given the step policies and their hooks:
      | policy | hook                         |
      | watch  | on step abnormal termination |
      | watch  | on step retry                |
      | watch  | on step failure              |
    Given a workflow "orders" with the steps:
      | step   | policies | rescue |
      | charge | watch    | yes    |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook                         |
      | watch  | on step abnormal termination |
    And the hooks received:
      | policy | hook            | calls |
      | watch  | on step retry   | 0     |
      | watch  | on step failure | 0     |
    And the journey succeeded

  @proposal-0134
  Scenario: FailWorkflow from the abnormal termination hook gives the step up instead of rescuing it
    Given the step policies and their hooks:
      | policy | hook                         | returns      | code |
      | watch  | on step abnormal termination | FailWorkflow | stop |
    Given a workflow "orders" with the steps:
      | step   | policies | rescue |
      | charge | watch    | yes    |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the events are exactly:
      | event                     | step   | attempt | policy | hook                         | lifecycle    | cause        | decided by                          |
      | journey_started           |        |         |        |                              |              |              |                                     |
      | pass_started              |        |         |        |                              |              |              |                                     |
      | attempt_started           | charge | 1       |        |                              |              |              |                                     |
      | step_abnormal_termination | charge | 1       |        |                              |              |              |                                     |
      | hook_called               | charge | 1       | watch  | on step abnormal termination | FailWorkflow |              |                                     |
      | step_given_up             | charge | 1       |        |                              |              | FailWorkflow | watch, on step abnormal termination |
      | journey_failed            | charge |         |        |                              |              |              | watch, on step abnormal termination |
    And the result names the step "charge" whose hook failed the journey, with the code "stop"

  Scenario: A step that fails again after its rescue is given up, and is not rescued twice
    Given a step policy "alarm" defines the hook "on step failure"
    Given the hook "on step failure" of policy "alarm" requests the failure cause
    Given a workflow "orders" with the steps:
      | step   | policies | rescue |
      | charge | alarm    | yes    |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | expired  |
      | 2       | failure | declined |
    And step "charge_rescue" succeeds
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | cause   |
      | step_rescuing  | charge | 1       | failure |
      | step_rescued   | charge | 1       |         |
      | step_failed    | charge | 2       |         |
      | step_given_up  | charge | 2       | failure |
      | journey_failed | charge |         | failure |
    And the hooks received:
      | policy | hook            | calls | cause   |
      | alarm  | on step failure | 1     | failure |
    And step "charge_rescue" was built 1 times, each time as a new instance
    And step "charge" ended as failed after 2 attempts
    And the result names the failed step "charge" with the code "declined"
