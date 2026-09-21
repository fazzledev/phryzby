require "minitest/autorun"
require_relative "../lib/physics"

class PhysicsTest < Minitest::Test
  def test_equality_inside_a_block_builds_an_equation_not_a_boolean
    equation = x == 5

    assert_kind_of Physics::Equation, equation
    refute_equal true, equation
  end

  def test_residual_is_zero_when_the_equation_holds
    assert_in_delta 0.0, (x == 5).residual(x: 5), 1e-12
    assert_in_delta 2.0, (x == 5).residual(x: 7), 1e-12
  end

  def test_a_number_on_the_left_still_builds_a_node
    assert_in_delta 0.0, (10 / x == 2).residual(x: 5), 1e-12
  end

  def test_an_equation_knows_which_variables_it_mentions
    assert_equal %i[a b c], (var(:a) + var(:b) == var(:c)).variables
  end

  def test_comparisons_build_conditions
    condition = x > 1

    assert_kind_of Physics::Comparison, condition
    assert condition.satisfied?(x: 2)
    refute condition.satisfied?(x: 0)
  end

  def test_an_unknown_name_in_a_block_is_caught_at_declaration
    error = assert_raises(NameError) do
      model { equation(:typo) { a == unknown_thing } }
    end

    assert_match(/unknown_thing/, error.message)
  end

  def test_a_missing_value_is_named_in_the_error
    klass = model { equation(:same) { a == b } }

    error = assert_raises(KeyError) { klass.new(a: 1).holds?(:same) }

    assert_match(/b/, error.message)
  end

  def test_subclasses_do_not_share_their_parents_variables
    first = model
    second = Class.new(Physics::Scenario) { quantity :only_there }

    assert first.quantities.key?(:a)
    refute second.quantities.key?(:a)
  end

  private

  def var(name) = Physics::Var.new(name)
  def x = var(:x)

  # A scenario holds values; only a law states equations. So the throwaway
  # model under test is a law composed into one.
  def model(&declarations)
    Physics::Scenario[law(&declarations)]
  end

  def law(&declarations)
    Module.new do
      extend Physics::Law
      quantity :a
      quantity :b
      instance_eval(&declarations) if declarations
    end
  end
end
