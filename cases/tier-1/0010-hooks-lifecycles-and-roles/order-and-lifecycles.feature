@tier-1 @proposal-0010
Feature: The order of hooks, and the lifecycles they return
  Checks points 2 to 5 of proposal 0010: which hooks run for each outcome and in
  what order, and what each step hook may return.

  Scenario: The retry hook runs only while a retry is possible; then only the failure hook runs
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
    And a step policy "policy" defines the hook "on step retry"
    And a step policy "alarm" defines the hook "on step failure"
    And the hook "on step failure" of policy "alarm" requests the failure cause
    And step "charge" has the policies "policy", "alarm"
    When the workflow runs
    Then the hook "on step retry" of policy "policy" was called 1 times
    And the hook "on step failure" of policy "alarm" was called 1 times
    And the hook "on step failure" of policy "alarm" received the cause "retries exhausted"
    And the journey failed

  Scenario: The abnormal termination hook runs before the failure hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    And a step policy "watch" defines the hook "on step abnormal termination"
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "watch", "alarm"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook                         |
      | watch  | on step abnormal termination |
      | alarm  | on step failure              |
    And the journey failed

  Scenario: FinishWorkflow from a success hook ends the journey as succeeded
    Given a workflow "orders" with the steps:
      | step   |
      | check  |
      | charge |
    And step "check" succeeds
    And step "charge" succeeds
    And a step policy "shortcut" defines the hook "on step success"
    And the hook "on step success" of policy "shortcut" returns FinishWorkflow
    And step "check" has the policies "shortcut"
    When the workflow runs
    Then step "check" ended as succeeded after 1 attempts
    And step "charge" ended as not executed after 0 attempts
    And the journey succeeded

  Scenario: FailWorkflow from a success hook fails the journey, and the step stays succeeded
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" contributes "amount" = 5000
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "limit" defines the hook "on step success"
    And the hook "on step success" of policy "limit" returns FailWorkflow with code "over limit"
    And step "charge" has the policies "limit"
    When the workflow runs
    Then step "charge" ended as succeeded after 1 attempts
    And step "ship" ended as not executed after 0 attempts
    And the result's data bag contains:
      | key    | value |
      | amount | 5000  |
    And the result names the step "charge" whose hook failed the journey, with the code "over limit"
    And the journey failed

  Scenario: FailWorkflow from a retry hook gives up at once, without the failure hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 3 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
    And a step policy "policy" defines the hook "on step retry"
    And the hook "on step retry" of policy "policy" returns FailWorkflow with code "give up"
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "policy", "alarm"
    When the workflow runs
    Then the hook "on step failure" of policy "alarm" was not called
    And step "charge" ended as failed after 1 attempts
    And the journey failed

  @invalid-lifecycle
  Scenario: A lifecycle a hook may not return aborts the journey
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "policy" defines the hook "on step failure"
    And the hook "on step failure" of policy "policy" returns FinishWorkflow
    And step "charge" has the policies "policy"
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "invalid lifecycle"
    And the journey was aborted
