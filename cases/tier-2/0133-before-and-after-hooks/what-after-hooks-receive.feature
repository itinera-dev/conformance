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
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 2 retries
    And step "charge" attempts:
      | attempt | outcome | code        | message |
      | 1       | failure | unreachable |         |
      | 2       | error   |             | timeout |
      | 3       | success |             |         |
    And its step policies and their hooks are:
      | policy | hook          | requests                   |
      | tx     | after attempt | ending                     |
      | tx     | after step    | ending, number of attempts |
    And a workflow policy "audit" defines the hook "after journey"
    And the hook "after journey" of policy "audit" requests its ending
    And the workflow has the policies "audit"
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the endings "failed", "abnormal termination", "succeeded"
    And the hook "after step" of policy "tx" received the endings "succeeded"
    And the hook "after step" of policy "tx" received the number of attempts 3
    And the hook "after journey" of policy "audit" received the endings "succeeded"
    And the journey succeeded

  Scenario: After attempt receives the failure's reason and the attempt's contributions, as optional
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | code     | message | details        | contributes        |
      | 1       | failure | declined | no      | {"limit": 100} | {"receipt": "R-1"} |
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" requests the optional failure reason
    And the hook "after attempt" of policy "tx" requests its optional error
    And the hook "after attempt" of policy "tx" requests optional step data "receipt" of type string
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the failure reason with code "declined", message "no" and details {"limit": 100}
    And the hook "after attempt" of policy "tx" received no error
    And the hook "after attempt" of policy "tx" received step data "receipt" = "R-1"
    And the journey failed

  Scenario: After attempt receives the error of an abnormal termination, as optional
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And a step policy "tx" defines the hook "after attempt"
    And the hook "after attempt" of policy "tx" requests the optional failure reason
    And the hook "after attempt" of policy "tx" requests its optional error
    When the workflow runs
    Then the hook "after attempt" of policy "tx" received the error with the message "timeout"
    And the hook "after attempt" of policy "tx" received no failure reason
    And the journey failed

  Scenario: After step receives the cause a step was given up for and its last reason
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" allows 1 retries
    And step "charge" attempts:
      | attempt | outcome | code     | message | details |
      | 1       | failure | declined | no      | {}      |
    And a step policy "tx" defines the hook "after step"
    And the hook "after step" of policy "tx" requests its ending
    And the hook "after step" of policy "tx" requests its number of attempts
    And the hook "after step" of policy "tx" requests its optional cause
    And the hook "after step" of policy "tx" requests the optional failure reason
    And a workflow policy "audit" defines the hook "after journey"
    And the hook "after journey" of policy "audit" requests its ending
    And the workflow has the policies "audit"
    When the workflow runs
    Then the hook "after step" of policy "tx" received the endings "failed"
    And the hook "after step" of policy "tx" received the number of attempts 2
    And the hook "after step" of policy "tx" received the cause "retries exhausted"
    And the hook "after step" of policy "tx" received the failure reason with code "declined", message "no" and details {}
    And the hook "after journey" of policy "audit" received the endings "failed"

  Scenario: After step receives the ending bypassed and no attempt, and nothing it cannot have
    Given a workflow "orders" with the steps:
      | step     | policies |
      | discount | gate     |
    And step "discount" succeeds
    And its step policies and their hooks are:
      | policy | hook        | returns | code | requests                                                            |
      | gate   | before step | bypass  | off  |                                                                     |
      | gate   | after step  |         |      | ending, number of attempts, optional failure reason, optional cause |
    When the workflow runs
    Then the hook "after step" of policy "gate" received the endings "bypassed"
    And the hook "after step" of policy "gate" received the number of attempts 0
    And the hook "after step" of policy "gate" received no failure reason
    And the hook "after step" of policy "gate" received no cause
    And the journey succeeded

  Scenario: Before hooks receive the step's name and the attempt number
    Given a workflow "orders" with the steps:
      | step   | policies |
      | charge | tx       |
    And step "charge" succeeds
    And its step policies and their hooks are:
      | policy | hook           | requests       |
      | tx     | before step    | step name      |
      | tx     | before attempt | attempt number |
    When the workflow runs
    Then the hook "before step" of policy "tx" received the step name "charge"
    And the hook "before attempt" of policy "tx" received the attempt number 1
    And the journey succeeded
