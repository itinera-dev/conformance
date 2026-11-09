@tier-2 @proposal-0133
Feature: The order of the hooks before and after a journey, a step and an attempt
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): `before journey` runs once before the first step and `after
  journey` once when the journey's ending is known; `before step` runs at the
  step's turn and `after step` when its status is about to become final;
  `before attempt` runs after `attempt_started` and `after attempt` right after
  the attempt's outcome fact. Any number of policies may define each of them;
  before hooks run in declaration order and after hooks in reverse, so that
  pairs nest. A step's contributions are committed once its after hooks have
  returned, before `on step success`.

  Scenario: The six hooks run around the journey, the step and each attempt
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code        | contributes        |
      | 1       | failure | unreachable |                    |
      | 2       | success |             | {"receipt": "R-1"} |
    And the step policies define the hooks:
      | policy | hook            |
      | tx     | before step     |
      | tx     | before attempt  |
      | tx     | after attempt   |
      | tx     | after step      |
      | tx     | on step retry   |
      | tx     | on step success |
    And step "charge" has the policies "tx"
    And the workflow policies define the hooks:
      | policy | hook                |
      | audit  | before journey      |
      | audit  | after journey       |
      | audit  | on workflow success |
    And the workflow has the policies "audit"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | attempt | key     | policy | hook                | lifecycle | cause   |
      | journey_started        |        |         |         |        |                     |           |         |
      | hook_called            |        |         |         | audit  | before journey      | none      |         |
      | hook_called            | charge |         |         | tx     | before step         | none      |         |
      | attempt_started        | charge | 1       |         |        |                     |           |         |
      | hook_called            | charge | 1       |         | tx     | before attempt      |           |         |
      | step_failed            | charge | 1       |         |        |                     |           |         |
      | hook_called            | charge | 1       |         | tx     | after attempt       |           |         |
      | hook_called            | charge | 1       |         | tx     | on step retry       | none      |         |
      | step_retrying          | charge | 1       |         |        |                     |           | failure |
      | attempt_started        | charge | 2       |         |        |                     |           |         |
      | hook_called            | charge | 2       |         | tx     | before attempt      |           |         |
      | step_succeeded         | charge | 2       |         |        |                     |           |         |
      | hook_called            | charge | 2       |         | tx     | after attempt       |           |         |
      | hook_called            | charge |         |         | tx     | after step          |           |         |
      | contribution_committed | charge | 2       | receipt |        |                     |           |         |
      | hook_called            | charge | 2       |         | tx     | on step success     | none      |         |
      | hook_called            |        |         |         | audit  | after journey       |           |         |
      | hook_called            |        |         |         | audit  | on workflow success |           |         |
      | journey_succeeded      |        |         |         |        |                     |           |         |
    And step "charge" ended as succeeded after 2 attempts
    And the journey succeeded

  Scenario: Before hooks run in declaration order and after hooks in reverse
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook           |
      | tx     | before step    |
      | tx     | before attempt |
      | tx     | after attempt  |
      | tx     | after step     |
      | lock   | before step    |
      | lock   | before attempt |
      | lock   | after attempt  |
      | lock   | after step     |
    And step "charge" has the policies "tx", "lock"
    And the workflow policies define the hooks:
      | policy | hook           |
      | audit  | before journey |
      | audit  | after journey  |
      | trace  | before journey |
      | trace  | after journey  |
    And the workflow has the policies "audit", "trace"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook           |
      | audit  | before journey |
      | trace  | before journey |
      | tx     | before step    |
      | lock   | before step    |
      | tx     | before attempt |
      | lock   | before attempt |
      | lock   | after attempt  |
      | tx     | after attempt  |
      | lock   | after step     |
      | tx     | after step     |
      | trace  | after journey  |
      | audit  | after journey  |
    And the journey succeeded

  Scenario: The attempt hooks run for every attempt, and the step hooks once per step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        |
      | 1       | failure | unreachable |
      | 2       | failure | unreachable |
      | 3       | success |             |
    And step "ship" succeeds
    And the step policies define the hooks:
      | policy | hook           |
      | tx     | before step    |
      | tx     | before attempt |
      | tx     | after attempt  |
      | tx     | after step     |
    And step "charge" has the policies "tx"
    And step "ship" has the policies "tx"
    When the workflow runs
    Then the hook "before step" of policy "tx" was called 2 times
    And the hook "after step" of policy "tx" was called 2 times
    And the hook "before attempt" of policy "tx" was called 4 times
    And the hook "after attempt" of policy "tx" was called 4 times
    And the journey succeeded

  Scenario: The step's after step hooks run before the journey moves to the next step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "tx" defines the hook "after step"
    And step "charge" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event           | step   | attempt | policy | hook       |
      | step_succeeded  | charge | 1       |        |            |
      | hook_called     | charge |         | tx     | after step |
      | attempt_started | ship   | 1       |        |            |

  Scenario: A step given up runs its after step hooks after step_given_up and before on step failure
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And the step policies define the hooks:
      | policy | hook            |
      | tx     | after attempt   |
      | tx     | after step      |
      | tx     | on step failure |
    And step "charge" has the policies "tx"
    And the workflow policies define the hooks:
      | policy | hook                |
      | audit  | after journey       |
      | audit  | on workflow failure |
    And the workflow has the policies "audit"
    When the workflow runs
    Then the events include, in order:
      | event          | step   | attempt | policy | hook                | cause   |
      | step_failed    | charge | 1       |        |                     |         |
      | hook_called    | charge | 1       | tx     | after attempt       |         |
      | step_given_up  | charge | 1       |        |                     | failure |
      | hook_called    | charge |         | tx     | after step          |         |
      | hook_called    | charge | 1       | tx     | on step failure     |         |
      | hook_called    |        |         | audit  | after journey       |         |
      | hook_called    |        |         | audit  | on workflow failure |         |
      | journey_failed | charge |         |        |                     | failure |
    And the result names the failed step "charge" with the code "declined"

  Scenario: An after-only policy runs its after hooks without any before hook
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the step policies define the hooks:
      | policy | hook          |
      | trail  | after attempt |
      | trail  | after step    |
    And step "charge" has the policies "trail"
    And a workflow policy "log" defines the hook "after journey"
    And the workflow has the policies "log"
    When the workflow runs
    Then the hooks were called in this order:
      | policy | hook          |
      | trail  | after attempt |
      | trail  | after step    |
      | log    | after journey |
    And the journey succeeded
