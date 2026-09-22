require "minitest/autorun"
require_relative "../../lib/physics"

class SolverTest < Minitest::Test
  include Physics

  def test_newton_finds_a_root_it_is_started_near
    assert_in_delta 2.0, Solver.newton(->(x) { x**2 - 4 }, 1.5), 1e-9
  end

  def test_newton_gives_up_on_a_flat_slope
    assert_nil Solver.newton(->(_x) { 1.0 }, 0.5)
  end

  def test_bisection_finds_a_root_newton_would_walk_past
    assert_in_delta Math::PI, Solver.bisect(->(x) { Math.sin(x) }, 2.0..4.0), 1e-9
  end

  def test_bisection_reports_nothing_when_the_range_holds_no_root
    assert_nil Solver.bisect(->(x) { x**2 + 1 }, -5.0..5.0)
  end

  def test_a_root_outside_the_declared_range_is_not_an_answer
    root = Solver.root(->(x) { Math.sin(x) }, guess: 3.0, within: 5.0..7.0)

    assert_in_delta 2 * Math::PI, root, 1e-9
  end

  def test_it_falls_back_to_bisection_when_newton_leaves_the_range
    residual = ->(x) { Math.sin(x) - 0.5 }
    root = Solver.root(residual, guess: 100.0, within: 0.0..(Math::PI / 2))

    assert_in_delta 30.0, root.in_degrees, 1e-6
  end

  # Nothing supplies a starting point: it comes from the declared range, which
  # is the only thing anyone knew about the answer in the first place.
  def test_it_starts_from_the_middle_of_the_range_when_not_told_where
    assert_in_delta Math::PI, Solver.root(->(x) { Math.sin(x) }, within: 2.0..4.0), 1e-9
  end

  def test_a_domain_error_is_not_a_root
    assert_nil Solver.newton(->(x) { Math.asin(x) - 2 }, 0.5)
  end
  # A residual is signed. Comparing it to a tolerance without taking its size
  # first calls any large negative number converged.
  def test_a_long_way_below_zero_is_not_converged
    assert_in_delta 8.0, Physics::Solver.newton(->(x) { x - 8 }, 5.0), 1e-9
  end

  def test_a_falling_residual_does_not_look_like_a_flat_one
    assert_in_delta 8.0, Physics::Solver.newton(->(x) { 8 - x }, 5.0), 1e-9
  end

  def test_running_out_of_steps_a_long_way_out_is_not_an_answer
    assert_nil Physics::Solver.newton(->(x) { -(x * x) - 1 }, 1.0)
  end

end
