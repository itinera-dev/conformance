@tier-1 @proposal-0003 @proposal-0060
Feature: Input adapters for rescue steps
  Checks proposal 0098, which amends proposals 0003 and 0060: an input adapter
  may be attached to a rescue step by its name, "<step name>_rescue", as to a
  step, but only for a step that has a rescue step, and at most one per rescue
  step. The rescue step's inputs are resolved through it as for any adapted
  step. An adapter attached to a step never serves its rescue step, and data
  from the rescued step is never asked of an adapter.
  Proposal 0116 adds that an adapter naming a rescue step twice in its list
  is attached to it twice, which is "step adapted twice".

  @proposal-0098
  Scenario: An adapter that returns nothing for a rescue step's input leaves it to the data bag
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key    | value |
      | client | "c-9" |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "client" of type string
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "credentials" for the steps "charge_rescue"
    And the input adapter "credentials" returns nothing for "client"
    When the workflow runs
    Then step "charge_rescue" was built with input "client" = "c-9"
    And the journey succeeded

  @proposal-0098
  Scenario: An adapter attached to a rescue step receives the rescue step's name
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" requests input "caller" of type string
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "caller" of type string
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "callers" for the steps "charge", "charge_rescue"
    And the input adapter "callers" requests the step name and returns it for "caller"
    When the workflow runs
    Then step "charge" was built for attempt 1 with input "caller" = "charge"
    And step "charge_rescue" was built with input "caller" = "charge_rescue"
    And step "charge" was built for attempt 2 with input "caller" = "charge"
    And the journey succeeded

  @proposal-0098
  Scenario: An adapter attached to a step is not asked for its rescue step's inputs
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And the data bag contains:
      | key   | value   |
      | token | "stale" |
    And step "charge" has a rescue step
    And step "charge" requests input "token" of type string
    And step "charge" attempts:
      | attempt | outcome | code    |
      | 1       | failure | expired |
      | 2       | success |         |
    And step "charge_rescue" requests input "token" of type string
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "credentials" for the steps "charge"
    And the input adapter "credentials" returns "fresh" for "token"
    When the workflow runs
    Then step "charge" was built for attempt 1 with input "token" = "fresh"
    And step "charge_rescue" was built with input "token" = "stale"
    And the journey succeeded

  @proposal-0098
  Scenario: Data from the rescued step is never asked of the rescue step's adapter
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" attempts:
      | attempt | outcome | code    | contributes        |
      | 1       | failure | expired | {"account": "A-1"} |
      | 2       | success |         |                    |
    And step "charge_rescue" requests rescued step data "account" of type string
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "accounts" for the steps "charge_rescue"
    And the input adapter "accounts" returns "A-2" for "account"
    When the workflow runs
    Then step "charge_rescue" was built with rescued step data "account" = "A-1"
    And the journey succeeded

  @proposal-0098 @proposal-0042
  Scenario: Two adapters attached to one rescue step are refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "credentials" for the steps "charge_rescue"
    And the workflow declares the input adapter "accounts" for the steps "charge_rescue"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  @proposal-0116 @proposal-0098 @proposal-0042
  Scenario: An adapter that names one rescue step twice is refused
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" has a rescue step
    And step "charge" succeeds
    And step "charge_rescue" succeeds
    And the workflow declares the input adapter "credentials" for the steps "charge_rescue", "charge_rescue"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  @proposal-0098 @proposal-0042
  Scenario: An adapter attached to a rescue step's name is refused when the step has no rescue step
    Given a workflow "orders" with the steps:
      | step   |
      | charge |
    And step "charge" succeeds
    And the workflow declares the input adapter "credentials" for the steps "charge_rescue"
    When the workflow is admitted
    Then admission is refused with the violations:
      | violation                      |
      | input adapter for unknown step |
    And no event was emitted
