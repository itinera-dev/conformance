@tier-1 @proposal-0054
Feature: How custom code fails
  Checks proposal 0054, which amends proposal 0049: hooks and reporters fail by
  throwing or by returning an error, and the journey is then aborted with "hook
  failed" or "reporter failed". Rules a language makes impossible to express are
  tagged in the scenarios that need them. Unrecoverable failures are not checked:
  nothing observable follows them.
  Amended by proposal 0083: an abort caused by failing custom code carries its
  error.

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

  @proposal-0083
  Scenario: A hook that fails carries its error in the abort
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And a step policy "ledger" defines the hook "on step success"
    And the hook "on step success" of policy "ledger" fails with "ledger closed"
    And step "charge" has the policies "ledger"
    When the workflow runs
    Then the events include, in order:
      | event           | code        | error         |
      | journey_aborted | hook failed | ledger closed |
    And the journey was aborted with the abort reason "hook failed"
    And the result's abort carries the error "ledger closed"

  @proposal-0083
  Scenario: A reporter that fails carries its error in the abort
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "fragile"
    And the reporter "fragile" fails with "disk full" on "attempt_started"
    And the executor is given a dispatcher holding the reporter "test"
    When the workflow runs
    Then the events include, in order:
      | event           | code            | error     |
      | journey_aborted | reporter failed | disk full |
    And the journey was aborted with the abort reason "reporter failed"
    And the result's abort carries the error "disk full"
