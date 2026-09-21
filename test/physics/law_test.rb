require "minitest/autorun"
require_relative "../../lib/physics"

class LawTest < Minitest::Test
  def test_a_law_is_not_a_model
    refute_operator law { }, :respond_to?, :new
  end

  def test_including_a_law_gives_the_model_its_equations
    model = Class.new(Physics::Scenario) { include LawTest.trivial }

    assert model.equations.key?(:trivial)
  end

  def test_two_laws_can_name_the_same_quantity
    model = Class.new(Physics::Scenario)
    model.include(law { variable :angle, alias: :a; variable :width, alias: :w })
    model.include(law { variable :angle, alias: :a; variable :depth, alias: :d })

    assert_equal %i[angle width depth], model.variables.values.uniq
  end

  def test_a_guarded_equation_is_passed_over_while_its_condition_is_false
    assert_in_delta 3.0, regime(x: 3.0).solve(:y), 1e-9
  end

  def test_a_guarded_equation_is_chosen_once_its_condition_holds
    assert_in_delta 1.0, regime(x: 30.0).solve(:y), 1e-9
  end

  def test_a_guard_whose_condition_cannot_be_evaluated_yet_does_not_apply
    assert_in_delta 1.0, regime(y: 1.0).solve(:x), 1e-9
  end

  def test_an_unguarded_equation_states_no_guard
    refute regime.class.guards.key?(:ordinary)
  end

  def regime(**values)
    law = self.class.law do
      variable :x, within: 0.0..50.0
      variable :y, within: 0.0..50.0

      condition(:extreme) { x > 10 }
      equation(:ordinary) { y == x }
      equation(:capped, when: :extreme) { y == 1 }
    end

    Physics::Scenario[law].new(**values)
  end

  def self.trivial
    law { variable :thing; equation(:trivial) { thing == 1 } }
  end

  def self.law(&declarations)
    Module.new do
      extend Physics::Law
      instance_eval(&declarations)
    end
  end

  private

  def law(&declarations) = self.class.law(&declarations)
end
