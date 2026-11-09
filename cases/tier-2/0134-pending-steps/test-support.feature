@tier-2 @proposal-0134 @capability-testing
Feature: Pending steps in test support
  Checks proposal 0134 (pending steps) with proposal 0108 (Test support): the
  path gains the lines `scheduled pass started`, `<step> attempt <n> pending`,
  `<step> deferred`, `<step> waiting`, `<step> selected` and `<step>
  abandoned`, and the causes `pending exhausted: budget` and `pending
  exhausted: deadline` for `<step> given up`. The ordered pass has no line, so
  the paths of journeys with no pending step stay as in tier 1. Scripted runs
  gain a pending ending, with or without a hint, and the attempts a step can
  have count its pending budget. A pending ending for a step not declared may
  be pending, or for a rescue step, is a mistake in the test.

  Scenario: The path of a journey with a pending step and a waiting step
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment |         |
      | receipt | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
      | 2       | success |
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                        |
      | payment attempt 1 pending   |
      | payment deferred            |
      | receipt waiting             |
      | scheduled pass started      |
      | payment selected            |
      | payment attempt 2 succeeded |
      | receipt selected            |
      | receipt attempt 1 succeeded |
      | journey succeeded           |

  Scenario: The path of a step given up when its pending budget is spent, and of a step abandoned
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
      | invoice |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 1
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    And step "invoice" may be pending, with a pending budget of 3
    And step "invoice" attempts:
      | attempt | outcome |
      | 1       | pending |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                         |
      | payment attempt 1 pending                    |
      | payment deferred                             |
      | invoice attempt 1 pending                    |
      | invoice deferred                             |
      | scheduled pass started                       |
      | payment selected                             |
      | payment attempt 2 pending                    |
      | payment given up: pending exhausted: budget  |
      | invoice abandoned                            |
      | journey failed at payment: pending exhausted |

  Scenario: A scripted pending ending, with a hint, defers the step
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And the script says:
      | step    | attempt   | ending   | hint          |
      | payment | 1         | pending  | {"after": 30} |
      | payment | remaining | real run |               |
    When the workflow runs with the script
    Then the events include, in order:
      | event          | step    | attempt | hint          |
      | step_pending   | payment | 1       | {"after": 30} |
      | step_deferred  | payment | 1       |               |
      | step_succeeded | payment | 2       |               |
    And the journey succeeded

  Scenario: The attempts a step can have count its pending budget
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 1
    And the script says:
      | step    | attempt | ending  |
      | payment | 1       | pending |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake          | step    | attempt |
      | attempt left out | payment | 2       |

  Scenario: A scripted pending ending for a step not declared may be pending is a mistake in the test
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the script says:
      | step    | attempt | ending  |
      | payment | 1       | pending |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake              | step    |
      | pending not declared | payment |

  Scenario: A scripted pending ending for a rescue step is a mistake in the test
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And step "payment" has a rescue step
    And step "payment_rescue" succeeds
    And the script says:
      | step           | attempt | ending  | code    |
      | payment        | 1       | failure | expired |
      | payment        | 2       | success |         |
      | payment_rescue | 1       | pending |         |
    When the workflow runs with the script
    Then the test stopped before the journey, naming:
      | mistake             | step           |
      | rescue step pending | payment_rescue |
