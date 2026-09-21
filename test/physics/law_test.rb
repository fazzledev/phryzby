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
    model.include(law { quantity :angle, variable: :a; quantity :width, variable: :w })
    model.include(law { quantity :angle, variable: :a; quantity :depth, variable: :d })

    assert_equal %i[angle width depth], model.quantities.values.uniq
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
      quantity :x, within: 0.0..50.0
      quantity :y, within: 0.0..50.0

      condition(:extreme) { x > 10 }
      equation(:ordinary) { y == x }
      equation(:capped, when: :extreme) { y == 1 }
    end

    Physics::Scenario[law].new(**values)
  end

  # A law being edited in a running VM is declared over and over. Each time
  # has to replace what was there, or a name you have thought better of goes
  # on being part of the law.
  def test_declaring_a_law_again_replaces_what_it_said
    law = self.class.law do
      quantity :first
      equation(:only) { first == 1 }
    end

    law.instance_eval do
      extend Physics::Law
      quantity :second
      equation(:other) { second == 2 }
    end

    assert_equal %i[second], law.quantities.values.uniq
    assert_equal %i[other], law.equations.keys
  end

  def test_a_law_it_includes_is_taken_up_again_too
    nouns = Module.new { extend Physics::Quantities; quantity :borrowed }
    law = self.class.law { }

    law.instance_eval do
      extend Physics::Law
      include nouns
      quantity :own
    end

    assert_equal %i[borrowed own], law.quantities.values.uniq
  end


  def self.trivial
    law { quantity :thing; equation(:trivial) { thing == 1 } }
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
