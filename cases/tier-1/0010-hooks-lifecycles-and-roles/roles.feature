@tier-1 @proposal-0010
Feature: Workflow roles
  Checks points 15 to 21 of proposal 0010: a hook requests a role as a
  parameter and calls its operations; a policy needing a role the workflow does
  not provide is refused at admission; one policy works in any workflow that
  provides its roles.

  Scenario: A hook calls an operation of a role the workflow provides
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow provides the role "notifier" with the operation "notify"
    And a step policy "tell" defines the hook "on step success"
    And the hook "on step success" of policy "tell" requests the role "notifier" and calls its operation "notify"
    And step "charge" has the policies "tell"
    When the workflow runs
    Then the operation "notify" of the role "notifier" was called 1 times
    And the journey succeeded

  Scenario: A policy needing a role the workflow does not provide is refused at admission
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "tell" defines the hook "on step success"
    And the hook "on step success" of policy "tell" requests the role "notifier" and calls its operation "notify"
    And step "charge" has the policies "tell"
    When the workflow runs
    Then admission is refused with the violations:
      | violation          |
      | role not provided  |
    And no step ran

  Scenario Outline: The same policy works in any workflow that provides its role
    Given a workflow "<workflow>" with the steps:
      | step   |
      | <step> |
    And step "<step>" succeeds
    And the workflow provides the role "notifier" with the operation "notify"
    And a step policy "tell" defines the hook "on step success"
    And the hook "on step success" of policy "tell" requests the role "notifier" and calls its operation "notify"
    And step "<step>" has the policies "tell"
    When the workflow runs
    Then the operation "notify" of the role "notifier" was called 1 times
    And the journey succeeded

    Examples:
      | workflow | step   |
      | orders   | charge |
      | refunds  | refund |
