@tier-2 @proposal-0134
Feature: Choosing which step to try next in the scheduled pass
  Checks proposal 0134 (pending steps): in the scheduled pass, an eligible
  step is a `Pending` step whose nbf has passed and whose awaited steps are
  done, or a `Waiting` step whose awaited steps are done. Among the eligible,
  the executor chooses the lower round first, then the greater effective
  weight, then the earlier nbf, then declared order; a step's effective weight
  is the greatest of its own and those of the steps that wait for it. A step is
  never chosen before its nbf, and when none is eligible the executor waits on
  its clock, after `journey_waiting`. Every time an event carries comes from
  the executor's clock, which the runner drives: it starts at
  2026-01-01T00:00:00.000Z and moves only when the executor waits, to the
  moment it waits for. The tie-break by earlier nbf needs attempts that take
  time, which proposal 0135 adds, and is checked with its cases.

  Scenario: A step is tried again only once its nbf has passed, and the executor waits for it
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment |         |
      | invoice | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 5000 ms
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | nbf  | nbf at                   | weight | deferrals left | until                    | timestamp                |
      | step_pending    | payment | 1       |      |                          |        |                |                          | 2026-01-01T00:00:00.000Z |
      | step_deferred   | payment | 1       | 5000 | 2026-01-01T00:00:05.000Z | 0      | 2              |                          | 2026-01-01T00:00:00.000Z |
      | step_succeeded  | invoice | 1       |      |                          |        |                |                          | 2026-01-01T00:00:00.000Z |
      | journey_waiting | payment |         |      |                          |        |                | 2026-01-01T00:00:05.000Z | 2026-01-01T00:00:00.000Z |
      | step_selected   | payment | 2       |      | 2026-01-01T00:00:05.000Z |        |                |                          | 2026-01-01T00:00:05.000Z |
      | attempt_started | payment | 2       |      |                          |        |                |                          | 2026-01-01T00:00:05.000Z |
      | step_succeeded  | payment | 2       |      |                          |        |                |                          | 2026-01-01T00:00:05.000Z |
    And the journey succeeded

  Scenario: Weight never lets a step be chosen before its nbf
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 1000 ms
    And step "payment" has a default weight of 10
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | until                    | timestamp                |
      | step_selected   | invoice | 2       |                          | 2026-01-01T00:00:00.000Z |
      | step_succeeded  | invoice | 2       |                          |                          |
      | journey_waiting | payment |         | 2026-01-01T00:00:01.000Z |                          |
      | step_selected   | payment | 2       |                          | 2026-01-01T00:00:01.000Z |
      | step_succeeded  | payment | 2       |                          |                          |
    And the journey succeeded

  Scenario: Among eligible steps of one round, the greater weight is chosen first
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" has a default weight of 5
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event         | step    | attempt | round | effective weight | over    | decided by |
      | step_selected | invoice | 2       | 0     | 5                | payment | default    |
      | step_selected | payment | 2       | 0     | 0                |         | default    |
    And the journey succeeded

  Scenario: Among eligible steps of one round and one weight, declared order decides
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event         | step    | attempt | over    |
      | step_selected | payment | 2       | invoice |
      | step_selected | invoice | 2       |         |
    And the journey succeeded

  Scenario: A light step is lifted by the weight of a heavy step that waits for it
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | audit  |         |
      | report |         |
      | notify | success |
    And the workflow allows pending steps
    And step "audit" may be pending, with a pending budget of 3
    And step "audit" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "report" may be pending, with a pending budget of 3
    And step "report" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "notify" may be pending, with a pending budget of 3
    And step "notify" has a default weight of 10
    And step "notify" waits for the steps "audit"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | steps                 | status before | round | effective weight | lifted from |
      | step_waiting   | notify |         | audit                 |               |       |                  |             |
      | pass_started   |        |         | audit, report, notify |               |       |                  |             |
      | step_selected  | audit  | 2       |                       | Pending       | 0     | 10               | notify      |
      | step_succeeded | audit  | 2       |                       |               |       |                  |             |
      | step_selected  | notify | 1       |                       | Waiting       | 0     | 10               |             |
      | step_succeeded | notify | 1       |                       |               |       |                  |             |
      | step_selected  | report | 2       |                       | Pending       | 0     | 0                |             |
      | step_succeeded | report | 2       |                       |               |       |                  |             |
    And step "notify" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: Every eligible step is tried once before any is tried again, whatever its weight
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default weight of 10
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | pending |
      | 3       | success |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | round |
      | step_selected  | payment | 2       | 0     |
      | step_pending   | payment | 2       |       |
      | step_deferred  | payment | 2       |       |
      | step_selected  | invoice | 2       | 0     |
      | step_succeeded | invoice | 2       |       |
      | step_selected  | payment | 3       | 1     |
      | step_succeeded | payment | 3       |       |
    And step "payment" ended as succeeded after 3 attempts
    And the journey succeeded
