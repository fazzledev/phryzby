# ruby test/pythagoras_test.rb

require "minitest/autorun"
require_relative "../lib/pythagoras"

# The engine, checked on a law everybody already knows the answers to.
class PythagorasTest < Minitest::Test
  def test_the_block_returned_an_equation_rather_than_a_boolean
    assert_kind_of Physics::Equation, Pythagoras.equations.fetch(:pythagoras)
  end

  def test_the_equation_remembers_how_it_was_written
    assert_equal "(hypotenuse ** 2) == ((leg_a ** 2) + (leg_b ** 2))",
                 Pythagoras.equations.fetch(:pythagoras).to_s
  end

  def test_an_alias_and_its_full_name_are_the_same_variable
    assert_in_delta 3.0, Pythagoras.new(leg_a: 3).[](:a), 1e-9
  end

  def test_it_solves_for_the_hypotenuse
    assert_in_delta 5.0, solved(:c, a: 3, b: 4), 1e-9
  end

  # The same declaration, asked the other way round. Nothing was rearranged.
  def test_it_solves_for_a_leg
    assert_in_delta 3.0, solved(:a, b: 4, c: 5), 1e-6
    assert_in_delta 4.0, solved(:b, a: 3, c: 5), 1e-6
  end

  # Squaring loses the sign, so the residual has a root at -3 as well. The
  # declared domain is the only thing that keeps the answer a length.
  def test_the_declared_domain_keeps_the_answer_positive
    assert_operator solved(:a, b: 4, c: 5), :>, 0
  end

  def test_a_solved_triangle_satisfies_the_law_it_was_solved_from
    triangle = Pythagoras.new(a: 3, b: 4)
    triangle.solve(:c, guess: 1.0)

    assert triangle.holds?(:pythagoras)
  end

  def test_refuses_to_solve_what_is_not_determined
    assert_raises(RuntimeError) { Pythagoras.new(a: 3).solve(:c, guess: 1.0) }
  end

  private

  def solved(target, **known)
    triangle = Pythagoras.new(**known)
    triangle.solve(target, guess: 1.0)
    triangle[target]
  end
end
