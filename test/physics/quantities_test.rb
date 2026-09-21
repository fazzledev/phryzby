require "minitest/autorun"
require_relative "../../lib/physics"

class QuantitiesTest < Minitest::Test
  def test_a_quantity_answers_to_its_alias_and_its_full_name
    declared = quantities { variable :angle, alias: :a }

    assert_equal :angle, declared.variables.fetch(:a)
    assert_equal :angle, declared.variables.fetch(:angle)
  end

  def test_a_declared_domain_is_kept_under_the_full_name
    assert_equal 0.0..1.5, quantities { variable :angle, alias: :a, within: 0.0..1.5 }
                             .domains.fetch(:angle)
  end

  def test_a_quantity_with_no_domain_declares_none
    refute quantities { variable :depth }.domains.key?(:depth)
  end

  def test_an_alias_is_optional
    declared = quantities { variable :depth }

    assert_equal({ depth: :depth }, declared.variables)
  end

  def test_two_laws_naming_the_same_quantity_mean_the_same_variable
    first = law { variable :angle, alias: :a; variable :width, alias: :w
                  equation(:one) { a == w } }
    second = law { variable :angle, alias: :a; variable :depth, alias: :d
                   equation(:two) { a == d * 2 } }

    scenario = Physics::Scenario[first, second].new(w: 3.0)

    assert_in_delta 1.5, scenario.solve(:d), 1e-9
    assert_equal %i[angle width depth], scenario.class.variables.values.uniq
  end

  def test_declaring_quantities_states_no_equations
    refute_respond_to quantities { variable :angle }, :equations
  end

  # Quantities are includable, because naming what exists is the thing every
  # law in a subject has in common. What they are not is a law: including them
  # brings the nouns and nothing else, because there is nothing else to bring.
  def test_including_quantities_brings_the_quantities
    scenario = Class.new(Physics::Scenario) { include QuantitiesTest.catalogue }

    assert_equal :angle, scenario.variables.fetch(:a)
    assert_equal 0.0..1.5, scenario.domains.fetch(:angle)
  end

  def test_quantities_state_no_equations_to_bring
    refute_respond_to QuantitiesTest.catalogue, :equations
    assert_empty Class.new(Physics::Scenario) { include QuantitiesTest.catalogue }.equations
  end

  def self.catalogue
    Module.new do
      extend Physics::Quantities
      variable :angle, alias: :a, within: 0.0..1.5
    end
  end

  private

  def quantities(&declarations)
    Module.new do
      extend Physics::Quantities
      instance_eval(&declarations)
    end
  end

  def law(&declarations)
    Module.new do
      extend Physics::Law
      instance_eval(&declarations)
    end
  end
end
