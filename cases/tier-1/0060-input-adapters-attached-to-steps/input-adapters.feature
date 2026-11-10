@tier-1 @proposal-0060
Feature: Input adapters attached to steps
  Checks proposal 0060, which amends proposal 0002: an input adapter is attached
  to steps, one per step; for an input it does not supply it returns nothing,
  and the input is read from the data bag.
  Spec defect #87: wrong type and required data missing name the adapter only
  when the adapter supplied the value.
  Proposal 0116, which amends proposals 0060 and 0095: two adapters with the
  same name are "duplicate adapter name", an adapter may share its name with a
  service provider, and an adapter naming one step twice in its list is
  attached to it twice, which is "step adapted twice".

  Scenario: An adapter returning nothing lets the data bag's value through
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs                            | outcome |
      | charge | amount: integer, currency: string | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag contains:
      | key      | value |
      | amount   | 42    |
      | currency | "EUR" |
    When the workflow runs
    Then the steps were built with:
      | step   | input    | value |
      | charge | amount   | 7     |
      | charge | currency | "EUR" |

  Scenario: One adapter serves two steps
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    And the input adapter "pricing" returns 7 when step "refund" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
      | refund | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the steps "charge", "refund"
    When the workflow runs
    Then the steps were built with:
      | step   | input  | value |
      | charge | amount | 7     |
      | refund | amount | 7     |

  Scenario: An adapter's missing required data from the workflow aborts the journey
    Given the input adapter "pricing" requests data from the workflow "price" of type integer
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag is empty
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key   | adapter | code                  |
      | journey_aborted | charge | price | pricing | required data missing |
    And no step ran

  Scenario: Two adapters on one step are refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the workflow binds the input adapter "discounts" to the step "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  Scenario: An adapter attached to a step that does not exist is refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the input adapter "pricing" to the step "ship"
    When the workflow runs
    Then admission is refused with the violations:
      | violation                       |
      | input adapter for unknown step  |
    And no event was emitted

  @proposal-0116
  Scenario: Two adapters with the same name are refused, even on different steps
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
      | refund | success |
    And the workflow declares the input adapter "pricing" for the steps "charge"
    And the workflow declares the input adapter "pricing" for the steps "refund"
    When the workflow runs
    Then admission is refused with the violations:
      | violation              |
      | duplicate adapter name |
    And no event was emitted

  @proposal-0116 @proposal-0095
  Scenario: An adapter and a service provider may have the same name
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    Given the service provider "pricing" makes a labeller for "payments", once per journey
    Given a workflow "orders" with the steps:
      | step   | inputs          | services           | outcome |
      | charge | amount: integer | payments: labeller | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the workflow binds the service provider "pricing"
    When the workflow runs
    Then step "charge" was built with input "amount" = 7
    And the service provider "pricing" was called 1 times
    And the journey succeeded

  @proposal-0116
  Scenario: An adapter that names one step twice is refused
    Given a workflow "orders" with the steps:
      | step   | outcome |
      | charge | success |
    And the workflow binds the input adapter "pricing" to the steps "charge", "charge"
    When the workflow runs
    Then admission is refused with the violations:
      | violation          |
      | step adapted twice |
    And no event was emitted

  @spec-defect-0087
  Scenario: A value of the wrong type from an adapter names the adapter
    Given the input adapter "pricing" returns "ten" when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    When the workflow runs
    Then the events include, in order:
      | event                  | step   | key    | adapter | code       |
      | input_adapter_supplied | charge | amount | pricing |            |
      | journey_aborted        | charge | amount | pricing | wrong type |
    And no step ran
    And the journey was aborted with the abort reason "wrong type"

  @spec-defect-0087
  Scenario: A value of the wrong type from the data bag does not name the adapter that returned nothing
    Given the input adapter "pricing" returns nothing when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag contains:
      | key    | value |
      | amount | "ten" |
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key    | code       |
      | journey_aborted | charge | amount | wrong type |
    And journey_aborted names no adapter
    And the journey was aborted with the abort reason "wrong type"

  @spec-defect-0087
  Scenario: Required data missing from the data bag does not name the adapter that returned nothing
    Given the input adapter "pricing" returns nothing when step "charge" requests "amount"
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag is empty
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key    | code                  |
      | journey_aborted | charge | amount | required data missing |
    And journey_aborted names no adapter
    And the journey was aborted with the abort reason "required data missing"

  @spec-defect-0092
  Scenario: An adapter's own requests are resolved in the order it declares them
    Given the input adapter "pricing" returns 7 when step "charge" requests "amount"
    And the input adapter "pricing" requests data from the workflow "price" of type integer
    And the input adapter "pricing" requests data from the workflow "quantity" of type integer
    Given a workflow "orders" with the steps:
      | step   | inputs          | outcome |
      | charge | amount: integer | success |
    And the workflow binds the input adapter "pricing" to the step "charge"
    And the data bag is empty
    When the workflow runs
    Then the events include, in order:
      | event           | step   | key   | adapter | code                  |
      | journey_aborted | charge | price | pricing | required data missing |
    And no step ran
