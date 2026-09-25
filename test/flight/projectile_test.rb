require "minitest/autorun"
require_relative "../../lib/flight/projectile"

# Nothing in the engine knows about light, and this is the chapter that says
# so: the same quantity, equation and solve, on a thrown ball.
class ProjectileTest < Minitest::Test
  THROW = Physics::Scenario.including(Projectile)
  EARTH = 9.81

  def thrown(**values) = THROW.new(g: EARTH, **values)

  def test_it_carries_a_throw_as_far_as_the_range_formula_does
    one = thrown(u: 20.0, theta_0: 45.deg)

    assert_in_delta 400.0 / EARTH, one.solve(:R), 1e-9
  end

  def test_it_reaches_the_height_the_vertical_speed_buys
    one = thrown(u: 20.0, theta_0: 30.deg)

    assert_in_delta 10.0**2 / (2 * EARTH), one.solve(:h), 1e-9
  end

  def test_it_stays_up_twice_as_long_as_it_takes_to_stop_climbing
    one = thrown(u: 20.0, theta_0: 90.deg)

    assert_in_delta 2 * 20.0 / EARTH, one.solve(:t_f), 1e-9
  end

  # Forty-five degrees is not written anywhere in the law. It is where the
  # range happens to peak, and the law is asked rather than told.
  def test_no_angle_throws_it_further_than_forty_five_degrees
    furthest = (1..89).max_by { |degrees| thrown(u: 20.0, theta_0: degrees.deg).solve(:R) }

    assert_equal 45, furthest
  end

  # The sideways question: not where it lands, but how to land it there.
  def test_it_answers_for_the_angle_that_reaches_a_mark
    asked = thrown(u: 20.0, theta_0: 45.deg).asking(:theta_0, R: 30.0)

    assert_in_delta 30.0, thrown(u: 20.0, theta_0: asked).solve(:R), 1e-6
  end

  def test_it_answers_for_the_speed_a_range_needs
    one = THROW.new(g: EARTH, theta_0: 45.deg, R: 400.0 / EARTH)

    assert_in_delta 20.0, one.solve(:u), 1e-6
  end

  # Where it is part way through, against where the whole-flight formulas say
  # it ends up: two routes to the same place, and the law was told neither
  # that they should agree nor that half way is the top.
  def test_half_way_through_is_half_the_range_and_all_of_the_peak
    half = thrown(u: 20.0, theta_0: 40.deg, k: 0.5)

    assert_in_delta half.solve(:R) / 2, half.solve(:x), 1e-9
    assert_in_delta half.solve(:h), half.solve(:y), 1e-9
    assert_in_delta 0.0, half.solve(:v_y), 1e-9
  end

  def test_at_the_end_it_is_back_on_the_ground_going_down_as_fast_as_it_went_up
    done = thrown(u: 20.0, theta_0: 40.deg, k: 1.0)

    assert_in_delta 0.0, done.solve(:y), 1e-9
    assert_in_delta done.solve(:R), done.solve(:x), 1e-9
    assert_in_delta(-20.0 * Math.sin(40.deg), done.solve(:v_y), 1e-9)
  end

  # Which way it is going, against the way it was sent: the law is told the
  # angle it left at and works the rest out, so the two agreeing at the start
  # is a check rather than an arrangement.
  def test_it_is_going_the_way_it_was_thrown_the_instant_it_is_thrown
    off = thrown(u: 20.0, theta_0: 37.deg, k: 0.0)

    assert_in_delta 37.deg, off.solve(:theta), 1e-9
  end

  def test_it_is_going_nowhere_upward_at_the_top
    assert_in_delta 0.0, thrown(u: 20.0, theta_0: 37.deg, k: 0.5).solve(:theta), 1e-9
  end

  # What it did going up it undoes coming down, so it lands as steeply as it
  # left and on the other side of level.
  def test_it_comes_down_as_steeply_as_it_went_up
    down = thrown(u: 20.0, theta_0: 37.deg, k: 1.0)

    assert_in_delta(-37.deg, down.solve(:theta), 1e-9)
  end

  # Nothing pushes it sideways, so nothing about sideways changes.
  def test_it_crosses_the_ground_at_one_speed_the_whole_way
    (0..10).map { |n| thrown(u: 20.0, theta_0: 40.deg, k: n / 10.0).solve(:v_x) }
           .each { |across| assert_in_delta 20.0 * Math.cos(40.deg), across, 1e-9 }
  end

  # The moment cannot be slid straight, because how long the flight lasts is
  # itself something the law works out. A part of it can be.
  def test_the_moment_follows_from_the_part_of_the_flight
    one = thrown(u: 20.0, theta_0: 40.deg, k: 0.25)

    assert_in_delta one.solve(:t_f) / 4, one.solve(:t), 1e-9
  end

  # A throw on the Moon goes six times as far, and the law is not told that
  # either — gravity is a quantity like any other.
  def test_gravity_is_something_the_scenario_is_given
    moon = THROW.new(g: 1.62, u: 20.0, theta_0: 45.deg)

    assert_in_delta EARTH / 1.62, moon.solve(:R) / thrown(u: 20.0, theta_0: 45.deg).solve(:R), 1e-9
  end
end
