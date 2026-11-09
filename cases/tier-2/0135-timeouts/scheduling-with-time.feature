@tier-2 @proposal-0134 @proposal-0135
Feature: Choosing pending steps while attempts take time
  Checks proposal 0134 (pending steps), with the attempts that take time on
  the executor's clock of proposal 0135: among eligible steps of one round and
  one weight, the earlier nbf is chosen first, before declared order; and the
  pending deadline is checked only when a pending is deferred, so a step chosen
  after its deadline because others ran first is still tried.

  Scenario: Among eligible steps of one round and one weight, the earlier nbf is chosen first
    Given a workflow "orders" with the steps:
      | step    |
      | invoice |
      | payment |
      | audit   |
    And the workflow allows pending steps
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" has a default nbf of 1000 ms
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 500 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "audit" may be pending, with a pending budget of 3
    And step "audit" attempts:
      | attempt | outcome | duration |
      | 1       | pending |          |
      | 2       | success | 3000 ms  |
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | over    | timestamp                |
      | step_selected  | audit   | 2       |         | 2026-01-01T00:00:00.000Z |
      | step_succeeded | audit   | 2       |         |                          |
      | step_selected  | payment | 2       | invoice | 2026-01-01T00:00:03.000Z |
      | step_succeeded | payment | 2       |         |                          |
      | step_selected  | invoice | 2       |         |                          |
    And the journey succeeded

  Scenario: A step chosen after its pending deadline because others ran first is still tried
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | audit   |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a pending deadline of 1000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "audit" may be pending, with a pending budget of 3
    And step "audit" has a default weight of 10
    And step "audit" attempts:
      | attempt | outcome | duration |
      | 1       | pending |          |
      | 2       | success | 5000 ms  |
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | timestamp                |
      | step_selected  | audit   | 2       |                          |
      | step_succeeded | audit   | 2       |                          |
      | step_selected  | payment | 2       | 2026-01-01T00:00:05.000Z |
      | step_succeeded | payment | 2       |                          |
    And step "payment" ended as succeeded after 2 attempts
    And the journey succeeded
