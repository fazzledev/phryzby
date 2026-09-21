require "minitest/autorun"
require_relative "../lib/pythagoras"

class PythagorasTest < Minitest::Test
  TRIANGLE = Physics::Scenario[Pythagoras]

  def test_the_block_returned_an_equation_rather_than_a_boolean
    assert_kind_of Physics::Equation, Pythagoras.equations.fetch(:pythagoras)
  end

  def test_the_equation_remembers_how_it_was_written
    assert_equal "(hypotenuse ** 2) == ((leg_a ** 2) + (leg_b ** 2))",
                 Pythagoras.equations.fetch(:pythagoras).to_s
  end

  def test_an_alias_and_its_full_name_are_the_same_variable
    assert_in_delta 3.0, TRIANGLE.new(leg_a: 3).[](:a), 1e-9
  end

  def test_it_solves_for_the_hypotenuse
    assert_in_delta 5.0, solved(:c, a: 3, b: 4), 1e-9
  end

  def test_it_solves_for_a_leg
    assert_in_delta 3.0, solved(:a, b: 4, c: 5), 1e-6
    assert_in_delta 4.0, solved(:b, a: 3, c: 5), 1e-6
  end

  def test_the_declared_domain_keeps_the_answer_positive
    assert_operator solved(:a, b: 4, c: 5), :>, 0
  end

  def test_a_solved_triangle_satisfies_the_law_it_was_solved_from
    triangle = TRIANGLE.new(a: 3, b: 4)
    triangle.solve(:c)

    assert triangle.holds?(:pythagoras)
  end

  def test_refuses_to_solve_what_is_not_determined
    assert_raises(RuntimeError) { TRIANGLE.new(a: 3).solve(:c) }
  end

  private

  def solved(target, **known)
    triangle = TRIANGLE.new(**known)
    triangle.solve(target)
    triangle[target]
  end
end
