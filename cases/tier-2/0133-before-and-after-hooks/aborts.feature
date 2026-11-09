@tier-2 @proposal-0133
Feature: After hooks after an abort
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): after `journey_aborted`, the after hooks run, nested: the `after
  attempt` hooks of the attempt that was running, then the `after step` hooks,
  then the `after journey` hooks, each once, in reverse declaration order, and
  only for a policy whose before hook at that level was called or that defines
  none. Nothing can abort again: the first abort reason stands. Every request
  of theirs for data is answered absent, and nothing they emit is delivered,
  since `journey_aborted` is the last event. An abort caused by an after hook
  runs the remaining after hooks the same way.

  Scenario: An abort during an attempt runs the after hooks of every level once, nested
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And its step policies and their hooks are:
      | policy | hook            | requests |
      | tx     | before step     |          |
      | tx     | before attempt  |          |
      | tx     | after attempt   | ending   |
      | tx     | after step      | ending   |
      | tx     | on step failure |          |
    And its workflow policies and their hooks are:
      | policy | hook                | requests |
      | audit  | before journey      |          |
      | audit  | after journey       | ending   |
      | audit  | on workflow failure |          |
    And the workflow has the policies "audit"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook           |
      | audit  | before journey |
      | tx     | before step    |
      | tx     | before attempt |
      | tx     | after attempt  |
      | tx     | after step     |
      | audit  | after journey  |
    And the hook "after attempt" of policy "tx" received the endings "aborted"
    And the hook "after step" of policy "tx" received the endings "aborted"
    And the hook "after journey" of policy "audit" received the endings "aborted"
    And the hook "on step failure" of policy "tx" was not called
    And the hook "on workflow failure" of policy "audit" was not called
    And the last event is "journey_aborted"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: After an abort, the after hooks' requests for data are answered absent
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag contains:
      | key   | value |
      | order | "A-1" |
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" requests optional data from the workflow "order" of type string
    And a workflow policy "audit" defines the hook "after journey"
    And the hook "after journey" of policy "audit" requests optional data from the workflow "order" of type string
    And the workflow has the policies "audit"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received data from the workflow "order" absent
    And the hook "after journey" of policy "audit" received data from the workflow "order" absent
    And the journey was aborted with the abort reason "required data missing"

  Scenario: What the after hooks emit after an abort reaches no reporter
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" emits journey_info "rolled back"
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" was called 1 times
    And the last event is "journey_aborted"
    And no event carries the message "rolled back"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: An after hook that fails after an abort does not change the abort, and the others still run
    Given a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And its step policies and their hooks are:
      | policy | hook          | fails with |
      | tx     | after attempt |            |
      | tx     | after step    |            |
      | audit  | after attempt | audit down |
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook          |
      | audit  | after attempt |
      | tx     | after attempt |
      | tx     | after step    |
    And the last event is "journey_aborted"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: An after-only policy whose instance for the attempt was never built runs nothing
    Given a workflow "orders" with the steps:
      | step   | policies       |
      | charge | broken, closer |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook            |
      | broken | on step success |
      | closer | after attempt   |
    And the policy "broken" fails when it is built
    When the workflow runs
    Then the hook "after attempt" of policy "closer" was not called
    And the journey was aborted with the abort reason "policy could not be built"

  Scenario: An abort caused by an after hook runs the remaining after hooks
    Given a workflow "orders" with the steps:
      | step   | policies  |
      | charge | tx, audit |
      | ship   |           |
    And step "charge" contributes "receipt" = "R-1"
    And step "charge" succeeds
    And step "ship" succeeds
    And the data bag contains:
      | key   | value |
      | order | "A-1" |
    And its step policies and their hooks are:
      | policy | hook          |
      | tx     | after attempt |
      | tx     | after step    |
      | audit  | after attempt |
    And the hook "after attempt" of policy "audit" requests optional data from the workflow "order" of type integer
    And a workflow policy "log" defines the hook "after journey"
    And the hook "after journey" of policy "log" requests its ending
    And the workflow has the policies "log"
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook          | key   | code       |
      | step_succeeded  | charge |        |               |       |            |
      | journey_aborted | charge | audit  | after attempt | order | wrong type |
    And the hook "after attempt" of policy "tx" was called 1 times
    And the hook "after step" of policy "tx" was called 1 times
    And the hook "after journey" of policy "log" received the endings "aborted"
    And no contribution of "receipt" was committed
    And step "ship" ended as not executed after 0 attempts
    And the journey was aborted with the abort reason "wrong type"
