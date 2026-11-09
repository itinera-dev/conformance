@tier-2 @proposal-0134
Feature: Steps that wait for pending steps
  Checks proposal 0134 (pending steps): a step that may be pending may name
  steps declared before it that it waits for. When its turn comes while a step
  it waits for is not done, it is not attempted: its `before step` hooks run,
  then `step_waiting`, it becomes `Waiting`, and the scan moves on. An awaited
  step is done when it is `Succeeded`, `Skipped` or `Bypassed`; the waiting
  step then becomes eligible in the scheduled pass, where its first attempt
  comes.

  Scenario: A step waits for a pending step, and runs once it has succeeded
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | receipt |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | steps            | status before | decided by |
      | step_deferred   | payment | 1       |                  |               |            |
      | step_waiting    | receipt |         | payment          |               | default    |
      | pass_started    |         |         | payment, receipt |               |            |
      | step_selected   | payment | 2       |                  | Pending       |            |
      | step_succeeded  | payment | 2       |                  |               |            |
      | step_selected   | receipt | 1       |                  | Waiting       |            |
      | attempt_started | receipt | 1       |                  |               |            |
      | step_succeeded  | receipt | 1       |                  |               |            |
    And step "receipt" ended as succeeded after 1 attempts
    And the journey succeeded

  Scenario: An awaited step that skips releases the step waiting for it
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | receipt |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | skipped |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    When the workflow runs
    Then the events include, in order:
      | event          | step    | attempt | status before |
      | step_skipped   | payment | 2       |               |
      | step_selected  | receipt | 1       | Waiting       |
      | step_succeeded | receipt | 1       |               |
    And step "payment" ended as skipped after 2 attempts
    And the journey succeeded

  Scenario: A step whose awaited step is already done is not waiting
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | receipt |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" succeeds
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the reporter "trace" did not receive the event "step_waiting"
    And the reporter "trace" received the event "pass_started" 1 times
    And the journey succeeded

  @proposal-0133
  Scenario: A bypassed awaited step is done, so the step waiting for it runs in the ordered pass
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | receipt |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" succeeds
    And a step policy "gate" defines the hook "before step"
    And the hook "before step" of policy "gate" bypasses with code "paid already"
    And step "payment" has the policies "gate"
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    And the workflow lists the reporters "trace"
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt |
      | step_bypassed   | payment |         |
      | attempt_started | receipt | 1       |
      | step_succeeded  | receipt | 1       |
    And the reporter "trace" did not receive the event "step_waiting"
    And the journey succeeded

  @proposal-0133
  Scenario: A waiting step's before step hooks run before step_waiting
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | receipt |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "receipt" succeeds
    And the step policies define the hooks:
      | policy | hook        |
      | tx     | before step |
      | tx     | after step  |
    And step "receipt" has the policies "tx"
    When the workflow runs
    Then the events include, in order:
      | event           | step    | attempt | policy | hook        |
      | hook_called     | receipt |         | tx     | before step |
      | step_waiting    | receipt |         |        |             |
      | step_selected   | receipt | 1       |        |             |
      | attempt_started | receipt | 1       |        |             |
      | step_succeeded  | receipt | 1       |        |             |
      | hook_called     | receipt |         | tx     | after step  |
    And the hook "before step" of policy "tx" was called 1 times
    And the journey succeeded
