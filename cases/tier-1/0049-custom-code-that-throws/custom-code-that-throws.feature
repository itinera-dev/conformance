@tier-1 @proposal-0049
Feature: Custom code that throws
  Checks proposal 0049, which amends proposals 0009 and 0011: the executor guards
  every call into custom code, and nothing custom code throws escapes run. A
  dispatcher that fails while reporters are added is a refusal; a
  role operation that throws inside a hook aborts with "hook failed"; a dispatcher
  that throws while dispatching aborts with "reporter failed"; and a throw while
  journey_aborted is delivered is ignored. Steps that throw, hooks that throw and
  reporters that throw are checked by the cases of proposals 0008, 0010 and 0011.

  Scenario: A dispatcher that throws while the journey's reporters are added is a refusal, with no event
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow lists the reporters "audit"
    And the executor is given a dispatcher holding the reporter "test" that throws when a reporter is added
    When the workflow runs
    Then run was refused
    And no event was emitted
    And no step ran

  Scenario: An input adapter that throws while a step is built aborts with "step could not be built"
    Given the input adapter "ledger" fails with "ledger down" when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "ledger" to the step "charge"
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "step could not be built"

  Scenario: A role operation that throws inside a hook aborts with "hook failed"
    Given a step policy "alert" defines the hook "on step success"
    Given the hook "on step success" of policy "alert" requests the role "notifier" and calls its operation "notify"
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | alert    | success |
    And the workflow provides the role "notifier" with the operation "notify"
    And the operation "notify" of the role "notifier" throws
    When the workflow runs
    Then the result names the step "charge" as where the journey was aborted, with the abort reason "hook failed"

  Scenario: A dispatcher that throws while dispatching aborts with "reporter failed"
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the executor is given a dispatcher holding the reporter "test" that throws when dispatching "attempt_started"
    When the workflow runs
    Then the journey was aborted with the abort reason "reporter failed"
    And the reporter "test" received the event "journey_aborted"
    And no step ran

  Scenario: A reporter that throws while journey_aborted is delivered changes nothing
    Given a step policy "broken" defines the hook "on step success"
    And the hook "on step success" of policy "broken" throws
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | broken   | success |
    And the workflow lists the reporters "fragile", "audit"
    And the reporter "fragile" throws on "journey_aborted"
    And the executor uses its default dispatcher
    When the workflow runs
    Then the journey was aborted with the abort reason "hook failed"
    And the reporter "audit" received the event "journey_aborted" 1 times
    And the last event is "journey_aborted"
