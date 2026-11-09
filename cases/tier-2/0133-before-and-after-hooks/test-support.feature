@tier-2 @proposal-0133 @capability-testing
Feature: Hooks before and after in test support
  Checks proposal 0133 (hooks before and after a journey, a step and an
  attempt) with proposal 0108 (Test support): the recording reporter assembles
  each line of the path from the fields of its event. The path gains `<step>
  bypassed`, followed by `: <reason>` when it has one; `<step> attempt <n>
  before hook failed: <error>` and `<step> attempt <n> after hook failed:
  <error>`, without `attempt <n>` at the step level and as `journey before hook
  failed: <error>` and `journey after hook failed: <error>` at the journey
  level; the causes `before hook failed` and `after hook failed` for `<step>
  given up`; and `journey failed: <reason>` when `journey_failed` names no step.

  Scenario: The path of a bypassed step, with and without a reason
    Given the step policies and their hooks:
      | policy | hook        | returns | code              |
      | gate   | before step | bypass  | no discount today |
      | wrap   | before step | bypass  |                   |
    Given a workflow "orders" with the steps:
      | step     | policies | outcome |
      | discount | gate     | success |
      | gift     | wrap     | success |
      | ship     |          | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                 |
      | discount bypassed: no discount today |
      | gift bypassed                        |
      | ship attempt 1 succeeded             |
      | journey succeeded                    |

  Scenario: The path of a failing before step
    Given the step policies and their hooks:
      | policy | hook        | fails with |
      | lock   | before step | no lock    |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | lock     | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                |
      | charge before hook failed: no lock  |
      | charge given up: before hook failed |
      | journey failed at charge: no lock   |

  Scenario: The path of a failing before attempt
    Given the step policies and their hooks:
      | policy | hook           | fails with    |
      | tx     | before attempt | no connection |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                               |
      | charge attempt 1 before hook failed: no connection |
      | charge given up: before hook failed                |
      | journey failed at charge: no connection            |

  Scenario: The path of a failing after attempt after a success
    Given the step policies and their hooks:
      | policy | hook          | fails with    |
      | tx     | after attempt | commit failed |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                              |
      | charge attempt 1 succeeded                        |
      | charge attempt 1 after hook failed: commit failed |
      | charge given up: after hook failed                |
      | journey failed at charge: commit failed           |

  Scenario: The path of a failing after step after a success
    Given the step policies and their hooks:
      | policy | hook       | fails with    |
      | tx     | after step | settle failed |
    Given a workflow "orders" with the steps:
      | step   | policies | outcome |
      | charge | tx       | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                    |
      | charge attempt 1 succeeded              |
      | charge after hook failed: settle failed |
      | charge given up: after hook failed      |
      | journey failed at charge: settle failed |

  Scenario: The path of a journey failed by before journey, which names no step
    Given the workflow policies and their hooks:
      | policy | hook           | returns      | code      |
      | check  | before journey | FailWorkflow | bad input |
    Given a workflow "orders" with the policies "check" and the steps:
      | step   | outcome |
      | charge | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                      |
      | journey failed: bad input |

  Scenario: The path of a failing before journey
    Given the workflow policies and their hooks:
      | policy | hook           | fails with        |
      | check  | before journey | rules unavailable |
    Given a workflow "orders" with the policies "check" and the steps:
      | step   | outcome |
      | charge | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                          |
      | journey before hook failed: rules unavailable |
      | journey aborted: hook failed                  |

  Scenario: The path of a failing after journey after a success
    Given the workflow policies and their hooks:
      | policy | hook          | fails with |
      | audit  | after journey | audit down |
    Given a workflow "orders" with the policies "audit" and the steps:
      | step   | outcome |
      | charge | success |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                  |
      | charge attempt 1 succeeded            |
      | journey after hook failed: audit down |
      | journey failed: audit down            |
