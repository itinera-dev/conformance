@tier-1 @proposal-0054
Feature: How custom code fails
  Checks proposal 0054, which amends proposal 0049: hooks and reporters fail by
  throwing or by returning an error, and the journey is then aborted with "hook
  failed" or "reporter failed". Rules a language makes impossible to express are
  tagged in the scenarios that need them. Unrecoverable failures are not checked:
  nothing observable follows them.

  Scenario: A hook that fails aborts the journey with "hook failed"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "broken" defines the hook "on step success"
    And the hook "on step success" of policy "broken" throws
    And step "charge" has the policies "broken"
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"

  Scenario: A reporter that fails aborts the journey with "reporter failed"
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "broken", "audit"
    And the reporter "broken" throws on "step_succeeded"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
