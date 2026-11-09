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
    Given the step policies and their hooks:
      | policy | hook            |
      | tx     | before step     |
      | tx     | before attempt  |
      | tx     | after attempt   |
      | tx     | after step      |
      | tx     | on step failure |
    Given the workflow policies and their hooks:
      | policy | hook                |
      | audit  | before journey      |
      | audit  | after journey       |
      | audit  | on workflow failure |
    Given the hooks request:
      | policy | hook          | request |
      | tx     | after attempt | ending  |
      | tx     | after step    | ending  |
      | audit  | after journey | ending  |
    Given a workflow "orders" with the policies "audit" and the steps:
      | step   | policies | inputs          | outcome |
      | charge | tx       | amount: integer | success |
    And the data bag is empty
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook           |
      | audit  | before journey |
      | tx     | before step    |
      | tx     | before attempt |
      | tx     | after attempt  |
      | tx     | after step     |
      | audit  | after journey  |
    And the hooks received:
      | policy | hook                | calls | endings |
      | tx     | after attempt       |       | aborted |
      | tx     | after step          |       | aborted |
      | audit  | after journey       |       | aborted |
      | tx     | on step failure     | 0     |         |
      | audit  | on workflow failure | 0     |         |
    And the last event is "journey_aborted"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: After an abort, the after hooks' requests for data are answered absent
    Given a step policy "tx" defines the hook "after attempt"
    Given a workflow policy "audit" defines the hook "after journey"
    Given the hooks request:
      | policy | hook          | request                | key   | type   | optional |
      | tx     | after attempt | data from the workflow | order | string | yes      |
      | audit  | after journey | data from the workflow | order | string | yes      |
    Given a workflow "orders" with the policies "audit" and the steps:
      | step   | policies | inputs          | outcome |
      | charge | tx       | amount: integer | success |
    And the data bag contains:
      | key   | value |
      | order | "A-1" |
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received data from the workflow "order" absent
    And the hook "after journey" of policy "audit" received data from the workflow "order" absent
    And the journey was aborted with the abort reason "required data missing"

  Scenario: What the after hooks emit after an abort reaches no reporter
    Given a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" emits journey_info "rolled back"
    Given a workflow "orders" with the steps:
      | step   | policies | inputs          | outcome |
      | charge | tx       | amount: integer | success |
    And the workflow lists the reporters "trace"
    And the data bag is empty
    When the workflow runs
    Then the hook "after attempt" of policy "tx" was called 1 times
    And the last event is "journey_aborted"
    And no event carries the message "rolled back"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: An after hook that fails after an abort does not change the abort, and the others still run
    Given the step policies and their hooks:
      | policy | hook          | fails with |
      | tx     | after attempt |            |
      | tx     | after step    |            |
      | audit  | after attempt | audit down |
    Given a workflow "orders" with the steps:
      | step   | policies  | inputs          | outcome |
      | charge | tx, audit | amount: integer | success |
    And the data bag is empty
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook          |
      | audit  | after attempt |
      | tx     | after attempt |
      | tx     | after step    |
    And the last event is "journey_aborted"
    And the journey was aborted with the abort reason "required data missing"

  Scenario: An after-only policy whose instance for the attempt was never built runs nothing
    Given the step policies and their hooks:
      | policy | hook            |
      | broken | on step success |
      | closer | after attempt   |
    And the policy "broken" fails when it is built
    Given a workflow "orders" with the steps:
      | step   | policies       | outcome |
      | charge | broken, closer | success |
    When the workflow runs
    Then the hook "after attempt" of policy "closer" was not called
    And the journey was aborted with the abort reason "policy could not be built"

  Scenario: An abort caused by an after hook runs the remaining after hooks
    Given the step policies and their hooks:
      | policy | hook          |
      | tx     | after attempt |
      | tx     | after step    |
      | audit  | after attempt |
    Given the workflow policies and their hooks:
      | policy | hook          |
      | log    | after journey |
    Given the hooks request:
      | policy | hook          | request                | key   | type    | optional |
      | log    | after journey | ending                 |       |         |          |
      | audit  | after attempt | data from the workflow | order | integer | yes      |
    Given a workflow "orders" with the policies "log" and the steps:
      | step   | policies  | outcome |
      | charge | tx, audit | success |
      | ship   |           | success |
    And step "charge" contributes "receipt" = "R-1"
    And the data bag contains:
      | key   | value |
      | order | "A-1" |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | policy | hook          | key   | code       |
      | step_succeeded  | charge |        |               |       |            |
      | journey_aborted | charge | audit  | after attempt | order | wrong type |
    And the hooks received:
      | policy | hook          | calls | endings |
      | tx     | after attempt | 1     |         |
      | tx     | after step    | 1     |         |
      | log    | after journey |       | aborted |
    And no contribution of "receipt" was committed
    And step "ship" ended as not executed after 0 attempts
    And the journey was aborted with the abort reason "wrong type"
