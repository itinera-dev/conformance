@tier-2 @proposal-0134
Feature: Pendings, retries, rescues and contributions
  Checks proposal 0134 (pending steps): trying a pending step again starts a
  new attempt with the next attempt number. Pendings do not spend the retry
  budget, which stays for failures, and a failure on a later attempt follows
  the retry and rescue rules of tier 1; a pending attempt is not a failure, so
  it is not rescued. A pending attempt's contributions are discarded, as a
  skipped attempt's are, with `contributions_discarded`.

  Background:
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 2

  Scenario: Pendings do not spend the retry budget
    Given step "payment" allows 1 retries
    And step "payment" attempts:
      | attempt | outcome | code        |
      | 1       | pending |             |
      | 2       | pending |             |
      | 3       | failure | unreachable |
      | 4       | success |             |
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | cause   |
      | step_pending    | payment | 1       |         |
      | step_deferred   | payment | 1       |         |
      | step_pending    | payment | 2       |         |
      | step_deferred   | payment | 2       |         |
      | step_failed     | payment | 3       |         |
      | step_retrying   | payment | 3       | failure |
      | attempt_started | payment | 4       |         |
      | step_succeeded  | payment | 4       |         |
    And step "payment" ended as succeeded after 4 attempts
    And the journey succeeded

  Scenario: A pending attempt is not rescued, and a failure after it is
    Given step "payment" has a rescue step
    And step "payment" attempts:
      | attempt | outcome | code    |
      | 1       | pending |         |
      | 2       | failure | expired |
      | 3       | success |         |
    And step "payment_rescue" succeeds
    When the workflow runs
    Then the events include, in order:
      | event           | step           | attempt | cause   | rescue         |
      | step_pending    | payment        | 1       |         |                |
      | step_deferred   | payment        | 1       |         |                |
      | step_selected   | payment        | 2       |         |                |
      | step_failed     | payment        | 2       |         |                |
      | step_rescuing   | payment        | 2       | failure | payment_rescue |
      | attempt_started | payment_rescue | 1       |         |                |
      | step_rescued    | payment        | 2       |         | payment_rescue |
      | attempt_started | payment        | 3       |         |                |
      | step_succeeded  | payment        | 3       |         |                |
    And the journey succeeded

  Scenario: A pending attempt's contributions are discarded
    Given step "payment" attempts:
      | attempt | outcome | contributes             |
      | 1       | pending | {"status": "requested"} |
      | 2       | success |                         |
    When the workflow runs
    Then the events include, in order:
      | event                   | step    | attempt |
      | step_pending            | payment | 1       |
      | contributions_discarded | payment | 1       |
      | step_deferred           | payment | 1       |
    And no contribution of "status" was committed
    And the result's data bag has no key "status"
    And the journey succeeded

  @proposal-0133
  Scenario: After attempt runs after each pending attempt, before its contributions are discarded and its decision
    Given step "payment" attempts:
      | attempt | outcome | contributes             |
      | 1       | pending | {"status": "requested"} |
      | 2       | success |                         |
    And the step policies and their hooks:
      | policy | hook            |
      | tx     | after attempt   |
      | tx     | on step pending |
    And the hook "after attempt" of policy "tx" requests its ending
    And step "payment" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event                   | step    | attempt | policy | hook            |
      | step_pending            | payment | 1       |        |                 |
      | hook_called             | payment | 1       | tx     | after attempt   |
      | contributions_discarded | payment | 1       |        |                 |
      | hook_called             | payment | 1       | tx     | on step pending |
      | step_deferred           | payment | 1       |        |                 |
    And the hook "after attempt" of policy "tx" received the endings "pending", "succeeded"
    And the journey succeeded
