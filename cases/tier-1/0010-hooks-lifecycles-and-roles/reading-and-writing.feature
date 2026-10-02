@tier-1 @proposal-0010
Feature: What hooks read and write, and hooks that throw
  Checks points 8 to 14 of proposal 0010: a hook that throws aborts the journey;
  hooks can request the attempt number, the journey ID and data from the
  workflow; hooks write only through a contributor, committed when they return.

  Scenario: A hook that throws aborts the journey, and no hook runs afterwards
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "broken" defines the hook "on step success"
    And the hook "on step success" of policy "broken" throws
    And step "charge" has the policies "broken"
    And a workflow policy "report" defines the hook "on workflow failure"
    And the workflow has the policies "report"
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "hook threw"
    And the hook "on workflow failure" of policy "report" was not called
    And step "ship" ended as not executed after 0 attempts
    And the journey was aborted

  Scenario: Hooks can request the attempt number and the journey ID
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow's ID generator returns "order-1"
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" requests the attempt number
    And the hook "on step success" of policy "audit" requests the journey ID
    And step "charge" has the policies "audit"
    When the workflow runs
    Then the hook "on step success" of policy "audit" received the attempt number 2
    And the hook "on step success" of policy "audit" received the journey ID "order-1"

  Scenario: A step hook's data from the workflow is resolved like an input of its step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key    | value |
      | amount | 42    |
    And the workflow declares an input adapter for step "charge" and key "amount" that returns 7
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" requests data from the workflow "amount" of type integer
    And step "charge" has the policies "audit"
    When the workflow runs
    Then the hook "on step success" of policy "audit" received data from the workflow "amount" = 7

  Scenario: A hook's contributions are committed when it returns, even when the step failed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "record" defines the hook "on step failure"
    And the hook "on step failure" of policy "record" contributes "decline" = "declined"
    And step "charge" has the policies "record"
    When the workflow runs
    Then the result's data bag contains:
      | key     | value      |
      | decline | "declined" |
    And the contribution of "decline" is recorded as made by the hook "on step failure" of policy "record"
    And the journey failed

  Scenario: A workflow hook's contributions are part of the journey's output
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "summary" defines the hook "on workflow success"
    And the hook "on workflow success" of policy "summary" contributes "summary" = "paid"
    And the workflow has the policies "summary"
    When the workflow runs
    Then the result's data bag contains:
      | key     | value  |
      | summary | "paid" |
    And the journey succeeded
