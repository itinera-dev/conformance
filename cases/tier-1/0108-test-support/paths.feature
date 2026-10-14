@tier-1 @proposal-0108 @capability-testing
Feature: A journey's path lists its flow as plain sentences
  Checks proposal 0108 (Test support): the path read from the recording
  reporter has one line for each attempt's outcome, each step decision and the
  journey's end, worded exactly as the proposal says, and nothing else.

  Scenario: A failure that is retried, then successes
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
      | 2       | success |          |
    And step "charge" allows 1 retries
    And step "charge" contributes "charged" = 40
    And step "ship" emits step_info "shipping"
    And step "ship" succeeds
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                              |
      | charge attempt 1 failed: declined |
      | charge retrying                   |
      | charge attempt 2 succeeded        |
      | ship attempt 1 succeeded          |
      | journey succeeded                 |

  Scenario: A skip with a reason, and one without
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" attempts:
      | attempt | outcome | code |
      | 1       | skipped | paid |
    And step "ship" attempts:
      | attempt | outcome |
      | 1       | skipped |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                           |
      | charge attempt 1 skipped: paid |
      | ship attempt 1 skipped         |
      | journey succeeded              |

  Scenario: A failure without a retry budget gives the step up at once
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                               |
      | charge attempt 1 failed: declined  |
      | charge given up: failure           |
      | journey failed at charge: declined |

  Scenario: An abnormal termination is retried within the budget
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
      | 2       | success |         |
    And step "charge" allows 1 retries
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                            |
      | charge attempt 1 terminated abnormally: timeout |
      | charge retrying                                 |
      | charge attempt 2 succeeded                      |
      | journey succeeded                               |

  Scenario: Retries that are exhausted fail the journey with the last attempt's reason
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And step "charge" allows 1 retries
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                               |
      | charge attempt 1 failed: declined  |
      | charge retrying                    |
      | charge attempt 2 failed: declined  |
      | charge given up: retries exhausted |
      | journey failed at charge: declined |

  Scenario: An abnormal termination that is not retried fails the journey with its error message
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | message |
      | 1       | error   | timeout |
    And step "charge" does not retry abnormal terminations
    And step "charge" allows 1 retries
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                            |
      | charge attempt 1 terminated abnormally: timeout |
      | charge given up: abnormal termination           |
      | journey failed at charge: timeout               |

  Scenario: A rescue
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" succeeds
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                               |
      | charge attempt 1 failed: expired   |
      | charge rescuing with charge_rescue |
      | charge_rescue attempt 1 succeeded  |
      | charge rescued by charge_rescue    |
      | charge attempt 2 succeeded         |
      | journey succeeded                  |

  Scenario: A step given up by a hook's FailWorkflow
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" attempts:
      | attempt | outcome | code     |
      | 1       | failure | declined |
    And step "charge" allows 1 retries
    And a step policy "fraud_check" defines the hook "on step retry"
    And the hook "on step retry" of policy "fraud_check" returns FailWorkflow with code "fraud"
    And step "charge" has the policies "fraud_check"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                           |
      | charge attempt 1 failed: declined              |
      | charge given up: FailWorkflow from fraud_check |
      | journey failed at charge: fraud                |

  Scenario: A journey a hook finished early
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
      | ship   |
    And step "charge" succeeds
    And step "ship" succeeds
    And a step policy "early_exit" defines the hook "on step success"
    And the hook "on step success" of policy "early_exit" returns FinishWorkflow
    And step "charge" has the policies "early_exit"
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                     |
      | charge attempt 1 succeeded               |
      | journey succeeded, decided by early_exit |

  Scenario: An abort that concerns a step names it
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" requests input "amount" of type integer
    And step "charge" succeeds
    And the data bag is empty
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                                             |
      | journey aborted at charge: required data missing |

  Scenario: An abort that concerns no step names none
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow lists the reporters "audit"
    And the reporter "audit" throws on "journey_started"
    And the executor uses its default dispatcher
    And the instance has the recording reporter of test support
    When the workflow runs
    Then the path is:
      | line                             |
      | journey aborted: reporter failed |

  Scenario: A refused run has an empty path
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the executor is given a dispatcher factory that fails
    And the instance has the recording reporter of test support
    When the workflow runs
    Then run was refused
    And the path is empty
