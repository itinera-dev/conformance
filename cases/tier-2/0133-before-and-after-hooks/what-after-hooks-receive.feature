@tier-2 @proposal-0133
Feature: What the after hooks receive
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt): `after attempt` may request the attempt's ending, the failure's
  reason, the error and the attempt's contributions; `after step` the step's
  ending, the number of attempts made, the last reason and error and the cause
  it was given up for; `after journey` the journey's ending. An attempt's
  ending is succeeded, failed, abnormal termination, skipped or aborted; a
  step's is succeeded, failed, skipped, bypassed or aborted; a journey's is
  succeeded, failed or aborted. The ending and the number of attempts always
  exist; everything else is requested as optional.

  Scenario: After attempt and after step receive the endings and the number of attempts of a step tried three times
    Given the step policies and their hooks:
      | policy | hook          |
      | tx     | after attempt |
      | tx     | after step    |
    Given the workflow policies and their hooks:
      | policy | hook          |
      | audit  | after journey |
    Given the hooks request:
      | policy | hook          | request            |
      | tx     | after attempt | ending             |
      | tx     | after step    | ending             |
      | tx     | after step    | number of attempts |
      | audit  | after journey | ending             |
    Given a workflow "orders" with the policies "audit" and the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        | message |
      | 1       | failure | unreachable |         |
      | 2       | error   |             | timeout |
      | 3       | success |             |         |
    When the workflow runs
    Then the hooks received:
      | policy | hook          | endings                                 | number of attempts |
      | tx     | after attempt | failed, abnormal termination, succeeded |                    |
      | tx     | after step    | succeeded                               | 3                  |
      | audit  | after journey | succeeded                               |                    |
    And the journey succeeded

  Scenario: After attempt receives the failure's reason and the attempt's contributions, as optional
    Given the step policies and their hooks:
      | policy | hook          |
      | tx     | after attempt |
    Given the hooks request:
      | policy | hook          | request        | key     | type   | optional |
      | tx     | after attempt | failure reason |         |        | yes      |
      | tx     | after attempt | error          |         |        | yes      |
      | tx     | after attempt | step data      | receipt | string | yes      |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | code     | message | details        | contributes        |
      | 1       | failure | declined | no      | {"limit": 100} | {"receipt": "R-1"} |
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the failure reason with code "declined", message "no" and details {"limit": 100}
    And the hook "after attempt" of policy "tx" received no error
    And the hook "after attempt" of policy "tx" received step data "receipt" = "R-1"
    And the journey failed

  Scenario: After attempt receives the error of an abnormal termination, as optional
    Given the step policies and their hooks:
      | policy | hook          |
      | tx     | after attempt |
    Given the hooks request:
      | policy | hook          | request        | optional |
      | tx     | after attempt | failure reason | yes      |
      | tx     | after attempt | error          | yes      |
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    When the workflow runs
    Then the hooks received:
      | policy | hook          | error   | failure reason |
      | tx     | after attempt | timeout | none           |
    And the journey failed

  Scenario: After step receives the cause a step was given up for and its last reason
    Given the step policies and their hooks:
      | policy | hook       |
      | tx     | after step |
    Given the workflow policies and their hooks:
      | policy | hook          |
      | audit  | after journey |
    Given the hooks request:
      | policy | hook          | request            | optional |
      | tx     | after step    | ending             |          |
      | tx     | after step    | number of attempts |          |
      | tx     | after step    | cause              | yes      |
      | tx     | after step    | failure reason     | yes      |
      | audit  | after journey | ending             |          |
    Given a workflow "orders" with the policies "audit" and the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code     | message | details |
      | 1       | failure | declined | no      | {}      |
    When the workflow runs
    Then the hooks received:
      | policy | hook          | endings | number of attempts | cause             |
      | tx     | after step    | failed  | 2                  | retries exhausted |
      | audit  | after journey | failed  |                    |                   |
    And the hook "after step" of policy "tx" received the failure reason with code "declined", message "no" and details {}

  Scenario: After step receives the ending bypassed and no attempt, and nothing it cannot have
    Given the step policies and their hooks:
      | policy | hook        | returns | code |
      | gate   | before step | bypass  | off  |
      | gate   | after step  |         |      |
    Given the hooks request:
      | policy | hook       | request            | optional |
      | gate   | after step | ending             |          |
      | gate   | after step | number of attempts |          |
      | gate   | after step | failure reason     | yes      |
      | gate   | after step | cause              | yes      |
    Given a workflow "orders" with the steps:
      | step     | policies | outcome |
      | discount | gate     | success |
    When the workflow runs
    Then the hooks received:
      | policy | hook       | endings  | number of attempts | cause | failure reason |
      | gate   | after step | bypassed | 0                  | none  | none           |
    And the journey succeeded

  Scenario: Before hooks receive the step's name and the attempt number
    Given the step policies and their hooks:
      | policy | hook           |
      | tx     | before step    |
      | tx     | before attempt |
    Given the hooks request:
      | policy | hook           | request        |
      | tx     | before step    | step name      |
      | tx     | before attempt | attempt number |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
    When the workflow runs
    Then the hooks received:
      | policy | hook           | attempt number | step name |
      | tx     | before step    |                | charge    |
      | tx     | before attempt | 1              |           |
    And the journey succeeded
