@tier-1 @proposal-0002
Feature: Policies
  Checks sections 3 and 4 of proposal 0002 (Foundations): each hook is defined
  at most once per step and per workflow, a duplicate is refused at admission
  before anything runs, every violation is reported together, and a step policy
  can request the name of the step it acts on.

  Scenario: Two step policies defining the same hook on one step are refused at admission
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And a step policy "metrics" defines the hook "on step success"
    And step "charge" has the policies "audit", "metrics"
    When the workflow runs
    Then admission is refused with the violations:
      | violation         |
      | hook defined twice |
    And no step ran

  Scenario: Two workflow policies defining the same hook are refused at admission
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a workflow policy "notify" defines the hook "on workflow success"
    And a workflow policy "archive" defines the hook "on workflow success"
    And the workflow has the policies "notify", "archive"
    When the workflow runs
    Then admission is refused with the violations:
      | violation         |
      | hook defined twice |
    And no step ran

  Scenario: Every violation is reported together
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And a step policy "metrics" defines the hook "on step success"
    And step "charge" has the policies "audit", "metrics"
    And a workflow policy "notify" defines the hook "on workflow success"
    And a workflow policy "archive" defines the hook "on workflow success"
    And the workflow has the policies "notify", "archive"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation         |
      | hook defined twice |
      | hook defined twice |

  Scenario: Policies defining different hooks on one step are accepted
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "audit" defines the hook "on step success"
    And a step policy "alarm" defines the hook "on step failure"
    And step "charge" has the policies "audit", "alarm"
    When the workflow runs
    Then the journey succeeded

  Scenario: A step policy receives the name of the step it acts on
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "audit" defines the hook "on step success"
    And the hook "on step success" of policy "audit" requests the step name
    And step "charge" has the policies "audit"
    And step "ship" has the policies "audit"
    When the workflow runs
    Then the hook "on step success" of policy "audit" received the step name "charge"
    And the hook "on step success" of policy "audit" received the step name "ship"
    And the journey succeeded
