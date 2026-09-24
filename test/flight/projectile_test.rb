require "minitest/autorun"
require_relative "../../lib/flight/projectile"

# Nothing in the engine knows about light, and this is the chapter that says
# so: the same quantity, equation and solve, on a thrown ball.
class ProjectileTest < Minitest::Test
  THROW = Physics::Scenario.including(Projectile)
  EARTH = 9.81

  def thrown(**values) = THROW.new(g: EARTH, **values)

  def test_it_carries_a_throw_as_far_as_the_range_formula_does
    one = thrown(u: 20.0, theta: 45.deg)

    assert_in_delta 400.0 / EARTH, one.solve(:x), 1e-9
  end

  def test_it_reaches_the_height_the_vertical_speed_buys
    one = thrown(u: 20.0, theta: 30.deg)

    assert_in_delta 10.0**2 / (2 * EARTH), one.solve(:h), 1e-9
  end

  def test_it_stays_up_twice_as_long_as_it_takes_to_stop_climbing
    one = thrown(u: 20.0, theta: 90.deg)

    assert_in_delta 2 * 20.0 / EARTH, one.solve(:t), 1e-9
  end

  # Forty-five degrees is not written anywhere in the law. It is where the
  # range happens to peak, and the law is asked rather than told.
  def test_no_angle_throws_it_further_than_forty_five_degrees
    furthest = (1..89).max_by { |degrees| thrown(u: 20.0, theta: degrees.deg).solve(:x) }

    assert_equal 45, furthest
  end

  # The sideways question: not where it lands, but how to land it there.
  def test_it_answers_for_the_angle_that_reaches_a_mark
    asked = thrown(u: 20.0, theta: 45.deg).asking(:theta, x: 30.0)

    assert_in_delta 30.0, thrown(u: 20.0, theta: asked).solve(:x), 1e-6
  end

  def test_it_answers_for_the_speed_a_range_needs
    one = THROW.new(g: EARTH, theta: 45.deg, x: 400.0 / EARTH)

    assert_in_delta 20.0, one.solve(:u), 1e-6
  end

  # A throw on the Moon goes six times as far, and the law is not told that
  # either — gravity is a quantity like any other.
  def test_gravity_is_something_the_scenario_is_given
    moon = THROW.new(g: 1.62, u: 20.0, theta: 45.deg)

    assert_in_delta EARTH / 1.62, moon.solve(:x) / thrown(u: 20.0, theta: 45.deg).solve(:x), 1e-9
  end
end
