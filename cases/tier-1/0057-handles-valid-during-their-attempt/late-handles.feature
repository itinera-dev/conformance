@tier-1 @proposal-0057 @late-handle
Feature: Contributors and step reporters are valid only during their attempt
  Checks proposal 0057, which amends proposals 0008 and 0010: a contributor or a
  step reporter used after its attempt has ended has no effect on any journey.

  Scenario: A step's contributor and reporter used after its attempt change nothing
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" keeps its contributor and step reporter
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "late" defines the hook "on step success"
    And the hook "on step success" of policy "late" uses the kept contributor and step reporter of step "charge" to contribute "stale" = 1 and emit step_info "stale"
    And step "ship" has the policies "late"
    When the workflow runs
    Then the journey succeeded
    And the result's data bag has no key "stale"
    And no event carries the message "stale"
