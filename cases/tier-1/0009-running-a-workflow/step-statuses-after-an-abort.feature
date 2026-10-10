@tier-1 @proposal-0009
Feature: The status of a step when the journey is aborted
  Checks spec defect #89, which clarifies proposal 0009: a step whose status was
  already final when the journey is aborted keeps it; a step that was executing,
  or about to be retried, becomes aborted.

  @spec-defect-0089
  Scenario: A step whose success hook fails stays succeeded
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "broken" defines the hook "on step success"
    And the hook "on step success" of policy "broken" throws
    And step "charge" has the policies "broken"
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"
    And step "charge" ended as succeeded after 1 attempts

  @spec-defect-0089
  Scenario: A step whose success a reporter fails on stays succeeded
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit", "fragile"
    And the reporter "fragile" throws on "step_succeeded"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And step "charge" ended as succeeded after 1 attempts

  @spec-defect-0089
  Scenario: A step whose failure hook fails stays failed
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And a step policy "broken" defines the hook "on step failure"
    And the hook "on step failure" of policy "broken" throws
    And step "charge" has the policies "broken"
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"
    And step "charge" ended as failed after 1 attempts

  @spec-defect-0089
  Scenario: A step whose retry hook fails is aborted
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And a step policy "broken" defines the hook "on step retry"
    And the hook "on step retry" of policy "broken" throws
    And step "charge" has the policies "broken"
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"
    And step "charge" ended as aborted after 1 attempts

  @spec-defect-0089
  Scenario: A step about to be retried is aborted when a reporter fails on its retry decision
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome           | code        |
      | 1       | retriable failure | unreachable |
      | 2       | success           |             |
    And the workflow lists the reporters "audit", "fragile"
    And the reporter "fragile" throws on "step_retrying"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And step "charge" ended as aborted after 1 attempts
