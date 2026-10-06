@tier-1 @proposal-0055
Feature: A reporter that fails while a step or hook runs
  Checks proposal 0055, which amends proposal 0011: delivery is blocking; when a
  reporter fails on an event a running step or hook emitted, the journey is
  aborted with "reporter failed" at once, the emit call ends the step or hook,
  and whatever it does afterwards is ignored.

  Background:
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the workflow lists the reporters "fragile", "audit"
    And the executor uses its default dispatcher

  Scenario: A step ends at the emit call, and nothing it did afterwards counts
    Given the reporter "fragile" throws on "step_info"
    And step "charge" emits step_info "first"
    And step "charge" emits step_info "second"
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And the reporter "audit" received the event "step_info" 1 times
    And the reporter "audit" did not receive the event "step_succeeded"
    And step "charge" ended as aborted after 1 attempts
    And the result's data bag has no key "receipt"
    And the last event is "journey_aborted"

  Scenario: A step that ignores the failure of its emit call is still aborted
    Given the reporter "fragile" throws on "step_info"
    And step "charge" ignores failures of its emit calls and carries on
    And step "charge" emits step_info "first"
    And step "charge" emits step_info "second"
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And no event carries the message "second"
    And the reporter "audit" did not receive the event "step_succeeded"
    And the result's data bag has no key "receipt"
    And the last event is "journey_aborted"

  Scenario: A hook ends at the emit call, and nothing it did afterwards counts
    Given the reporter "fragile" throws on "journey_info"
    And step "charge" succeeds
    And a step policy "audit-policy" defines the hook "on step success"
    And the hook "on step success" of policy "audit-policy" emits journey_info "checked"
    And the hook "on step success" of policy "audit-policy" contributes "note" = "seen"
    And step "charge" has the policies "audit-policy"
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And the reporter "audit" did not receive the event "hook_called"
    And the result's data bag has no key "note"
