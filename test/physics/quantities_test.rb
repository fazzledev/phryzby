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

  # It is not a law, so including it into a scenario is not a way to get its
  # quantities. A law states what it is about, in full, where it is written.
  def test_including_bare_quantities_into_a_scenario_absorbs_nothing
    scenario = Class.new(Physics::Scenario) { include QuantitiesTest.catalogue }

    assert_empty scenario.variables
  end

  def self.catalogue = Module.new { extend Physics::Quantities; variable :angle }

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
