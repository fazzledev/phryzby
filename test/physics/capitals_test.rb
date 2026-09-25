require "minitest/autorun"
require_relative "../../lib/physics"

# A law may write a quantity with a capital, because some quantities have one
# and differ from another quantity only by it: G is not g. Ruby reads a bare
# capital inside the law as a constant rather than a call, so the law makes
# one — and everything that is true of a lowercase name has to stay true.
class CapitalsTest < Minitest::Test
  module Pulling
    extend Physics::Law

    quantity :gravitation,   variable: :G
    quantity :gravity,       variable: :g
    quantity :mass,          variable: :m
    quantity :how_far_apart, variable: :d

    equation(:newtons_law) { g == G * m / d**2 }
  end

  def test_a_capital_reaches_the_quantity_the_way_a_small_letter_does
    assert_equal "g == ((G * m) / (d ** 2))", Pulling.equations.fetch(:newtons_law).to_s
    assert_equal :gravitation, Pulling.quantities.fetch(:G)
  end

  # Earth: 5.972e24 kg at 6.371e6 m comes to 9.82 and a bit.
  def test_it_solves_for_either_of_them
    earth = Physics::Scenario.including(Pulling)
                             .new(G: 6.674e-11, m: 5.972e24, d: 6.371e6)

    assert_in_delta 9.82, earth.solve(:g), 0.01
    assert_in_delta 6.674e-11, Physics::Scenario.including(Pulling)
                                                .new(g: 9.82, m: 5.972e24, d: 6.371e6).solve(:G),
                    1e-13
  end

  # G and g are told apart, which is the whole reason for allowing the capital.
  def test_the_capital_and_the_small_letter_are_different_quantities
    refute_equal Pulling.quantities.fetch(:G), Pulling.quantities.fetch(:g)
  end

  def test_it_is_written_the_way_it_was_declared
    assert_equal "G", Physics.symbol(:G)
    assert_equal "<mi>G</mi>", Physics.notation(:G)
  end

  # A law that takes up another can write what that one declared.
  def test_a_law_that_includes_it_can_write_it_too
    borrower = Module.new do
      extend Physics::Law
      include Pulling
      quantity :weight, variable: :w
    end
    borrower.equation(:weighs) { w == m * g }

    assert_equal :gravitation, borrower.quantities.fetch(:G)
    assert_equal borrower.const_get(:G), Pulling.const_get(:G)
  end

  SOURCE = <<~RB
    module Reopened
      extend Physics::Law
      quantity :gravitation, variable: :G
      quantity :mass,        variable: :m
      equation(:pulls) { G == m }
    end
  RB

  # The page re-evaluates a law every time it is run, so declaring it again
  # has to be silent — and has to leave one constant, not a warning.
  def test_declaring_the_same_law_again_says_nothing
    said = capture_io { 3.times { eval(SOURCE, TOPLEVEL_BINDING) } }.last # rubocop:disable Security/Eval

    assert_empty said
    assert_equal :gravitation, Reopened.quantities.fetch(:G)
  end

  # And a law edited to drop the quantity drops the constant, so an equation
  # cannot go on reaching a name the law no longer declares.
  def test_a_law_that_drops_it_drops_the_constant
    eval(SOURCE, TOPLEVEL_BINDING) # rubocop:disable Security/Eval
    assert Reopened.const_defined?(:G, false)

    eval("module Reopened; extend Physics::Law; quantity :mass, variable: :m; end", # rubocop:disable Security/Eval
         TOPLEVEL_BINDING)

    refute Reopened.const_defined?(:G, false)
  end
end
