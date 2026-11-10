@tier-1 @proposal-0010
Feature: The order of hooks, and the lifecycles they return
  Checks points 2 to 5 of proposal 0010: which hooks run for each outcome and in
  what order, and what each step hook may return.

  @proposal-0106
  Scenario: The retry hook runs only while a retry is possible; then only the failure hook runs
    Given the step policies and their hooks:
      | policy | hook            |
      | policy | on step retry   |
      | alarm  | on step failure |
    Given the hook "on step failure" of policy "alarm" requests the failure cause
    Given a workflow "orders" with the steps:
      | step   | policies      |
      | charge | policy, alarm |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    When the workflow runs
    Then the hooks received:
      | policy | hook            | calls | cause             |
      | policy | on step retry   | 1     |                   |
      | alarm  | on step failure | 1     | retries exhausted |
    And the journey failed

  Scenario: The abnormal termination hook runs before the failure hook
    Given the step policies and their hooks:
      | policy | hook                         |
      | watch  | on step abnormal termination |
      | alarm  | on step failure              |
    Given a workflow "orders" with the steps:
      | step   | policies     |
      | charge | watch, alarm |
    And step "charge" attempts:
      | attempt | outcome |
      | 1       | error   |
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook                         |
      | watch  | on step abnormal termination |
      | alarm  | on step failure              |
    And the journey failed

  Scenario: FinishWorkflow from a success hook ends the journey as succeeded
    Given the step policies and their hooks:
      | policy   | hook            | returns        |
      | shortcut | on step success | FinishWorkflow |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | check  | shortcut | success |
      | charge |          | success |
    When the workflow runs
    Then the steps ended as:
      | step   | status       | attempts |
      | check  | succeeded    | 1        |
      | charge | not executed | 0        |
    And the journey succeeded

  Scenario: FailWorkflow from a success hook fails the journey, and the step stays succeeded
    Given the step policies and their hooks:
      | policy | hook            | returns      | code       |
      | limit  | on step success | FailWorkflow | over limit |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | limit    | success |
      | ship   |          | success |
    And step "charge" contributes "amount" = 5000
    When the workflow runs
    Then the steps ended as:
      | step   | status       | attempts |
      | charge | succeeded    | 1        |
      | ship   | not executed | 0        |
    And the result's data bag contains:
      | key    | value |
      | amount | 5000  |
    And the result names the step "charge" whose hook failed the journey, with the code "over limit"
    And the journey failed

  @proposal-0106
  Scenario: FailWorkflow from a retry hook gives up at once, without the failure hook
    Given the step policies and their hooks:
      | policy | hook            | returns      | code    |
      | policy | on step retry   | FailWorkflow | give up |
      | alarm  | on step failure |              |         |
    Given a workflow "orders" with the steps:
      | step   | policies      |
      | charge | policy, alarm |
    And step "charge" allows 3 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
    When the workflow runs
    Then the hook "on step failure" of policy "alarm" was not called
    And step "charge" ended as failed after 1 attempts
    And the journey failed

  @invalid-lifecycle
  Scenario: A lifecycle a hook may not return aborts the journey
    Given the step policies and their hooks:
      | policy | hook            | returns        |
      | policy | on step failure | FinishWorkflow |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | policy   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "invalid lifecycle"
    And the journey was aborted
