require "minitest/autorun"
require_relative "../../lib/light/reflection"

class ReflectionTest < Minitest::Test
  def test_reflection_equals_incidence
    assert_in_delta 37.0, solved(:rl, i: 37), 1e-6
  end

  def test_it_solves_the_other_way_round_too
    assert_in_delta 37.0, solved(:i, rl: 37), 1e-6
  end

  def test_the_equation_block_builds_an_equation_rather_than_a_boolean
    assert_kind_of Physics::Equation, Reflection.equations.fetch(:law_of_reflection)
  end

  def test_a_solved_ray_satisfies_the_law_it_was_solved_from
    ray = Interface.new(i: 37.deg)
    ray.solve(:rl, guess: 0.4)

    assert ray.holds?(:law_of_reflection)
  end

  def test_a_wrong_angle_does_not_satisfy_it
    refute Interface.new(i: 37.deg, rl: 25.deg).holds?(:law_of_reflection)
  end

  def test_aliases_and_full_names_are_the_same_variable
    ray = Interface.new(angle_of_incidence: 30.deg)

    assert_in_delta 30.0, ray[:i].in_degrees, 1e-9
  end

  def test_refuses_to_solve_what_is_not_determined
    assert_raises(RuntimeError) { Interface.new.solve(:rl, guess: 0.4) }
  end

  private

  def solved(target, **angles)
    ray = Interface.new(**angles.transform_values(&:deg))
    ray.solve(target, guess: 0.4)
    ray[target].in_degrees
  end
end
