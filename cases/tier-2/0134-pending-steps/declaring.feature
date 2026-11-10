@tier-2 @proposal-0134
Feature: Declaring pending steps
  Checks proposal 0134 (pending steps): a step that may be pending is declared
  so on its step descriptor, with a pending budget of at least 1, and a
  workflow that has one declares that it allows pending steps. A step not
  declared so, or a rescue step, that reports pending aborts the journey with
  `pending not declared`. The violations `pending not allowed`, `invalid
  pending wait`, `pending budget missing` and `invalid pending setting` are
  found when the workflow is built. Durations are whole milliseconds, and one
  with a fraction of a millisecond is refused, never rounded. The listing
  shows whether the workflow allows pending steps, and each such step's waits
  and settings.

  @pending-not-declared
  Scenario: A step not declared may be pending that reports pending aborts the journey
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And step "payment" attempts:
      | attempt | outcome |
      | 1       | pending |
    When the workflow runs
    Then the events include, in order:
      | event           | step    | code                 |
      | journey_aborted | payment | pending not declared |
    And the journey was aborted with the abort reason "pending not declared"

  @rescue-pending
  Scenario: A rescue step that reports pending aborts the journey
    Given a workflow "orders" with the steps:
      | step    |
      | payment |
    And step "payment" has a rescue step
    And step "payment" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
    And step "payment_rescue" attempts:
      | attempt | outcome |
      | 1       | pending |
    When the workflow runs
    Then the events include, in order:
      | event           | step           | code                 |
      | journey_aborted | payment_rescue | pending not declared |
    And the journey was aborted with the abort reason "pending not declared"

  Scenario: A step that may be pending in a workflow that does not allow it is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And step "payment" may be pending, with a pending budget of 3
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation           |
      | pending not allowed |

  Scenario: Waiting for a step the workflow does not have is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | receipt | success |
    And the workflow allows pending steps
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | invalid pending wait |

  Scenario: Waiting for a step that cannot be pending is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
      | receipt | success |
    And the workflow allows pending steps
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | invalid pending wait |

  Scenario: Waiting for itself is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | receipt | success |
    And the workflow allows pending steps
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "receipt"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | invalid pending wait |

  Scenario: Waiting for a step declared later is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | receipt | success |
      | payment | success |
    And the workflow allows pending steps
    And step "receipt" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    And step "payment" may be pending, with a pending budget of 3
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation            |
      | invalid pending wait |

  Scenario: A step that may be pending with no pending budget is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with no pending budget
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | pending budget missing |

  Scenario: A pending budget of 0 is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 0
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation              |
      | pending budget missing |

  Scenario: A negative default nbf is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of -1 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation               |
      | invalid pending setting |

  Scenario: A pending deadline of 0 is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a pending deadline of 0 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation               |
      | invalid pending setting |

  Scenario: A pending setting on a step that cannot be pending is refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" has a default weight of 3
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation               |
      | invalid pending setting |

  Scenario: Waits declared by a step that cannot be pending are refused
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
      | receipt | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "receipt" waits for the steps "payment"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation               |
      | invalid pending setting |

  @fractional-duration
  Scenario: A duration with a fraction of a millisecond is refused, not rounded
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 1.5 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation               |
      | invalid pending setting |

  Scenario: The listing shows that the workflow allows pending steps, and each pending step's waits and settings
    Given a workflow "orders" with the steps:
      | step    | outcome |
      | payment | success |
      | receipt | success |
      | ship    | success |
    And the workflow allows pending steps
    And step "payment" may be pending, with a pending budget of 3
    And step "payment" has a default nbf of 1000 ms
    And step "payment" has a default weight of 2
    And step "payment" has a pending deadline of 60000 ms
    And step "receipt" may be pending, with a pending budget of 1
    And step "receipt" waits for the steps "payment"
    When the workflow is listed
    Then the listing allows pending steps
    And the listing is:
      | step    | position | policies | adapter | pending budget | waits   | pending deadline | nbf  | weight |
      | payment | 1        |          |         | 3              |         | 60000            | 1000 | 2      |
      | receipt | 2        |          |         | 1              | payment |                  | 0    | 0      |
      | ship    | 3        |          |         |                |         |                  |      |        |
