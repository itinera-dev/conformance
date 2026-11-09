@tier-2 @proposal-0135
Feature: Declaring timeouts
  Checks proposal 0135 (journey and attempt timeouts): an attempt timeout may
  be set on a step descriptor and a journey timeout on the workflow
  descriptor, each a duration greater than 0, in whole milliseconds. A timeout
  of 0 or less, or with a fraction of a millisecond, is the violation `invalid
  timeout`, found when the workflow is built, and never rounded. The listing
  shows each step's attempt timeout and the workflow's journey timeout.

  Scenario: An attempt timeout of 0 is refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" has an attempt timeout of 0 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation       |
      | invalid timeout |

  Scenario: A negative attempt timeout is refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" has an attempt timeout of -1000 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation       |
      | invalid timeout |

  Scenario: A journey timeout of 0 is refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow has a journey timeout of 0 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation       |
      | invalid timeout |

  @fractional-duration
  Scenario: A timeout with a fraction of a millisecond is refused, not rounded
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And step "charge" has an attempt timeout of 1000.5 ms
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation       |
      | invalid timeout |

  Scenario: The listing shows the attempt timeouts and the journey timeout
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
      | ship   | success |
    And the workflow has a journey timeout of 86400000 ms
    And step "charge" has an attempt timeout of 5000 ms
    When the workflow is listed
    Then the listing has the journey timeout 86400000
    And the listing is:
      | step   | position | policies | adapter | attempt timeout |
      | charge | 1        |          |         | 5000            |
      | ship   | 2        |          |         |                 |
