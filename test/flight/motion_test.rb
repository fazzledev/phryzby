require "minitest/autorun"
require_relative "../../lib/flight/motion"

# Where it is while it is still going, against where the chapter before says
# it ends up. The law is told neither that the two should agree nor that half
# way is the top — both fall out.
class MotionTest < Minitest::Test
  MOVING = Physics::Scenario.including(Motion)
  EARTH = 9.81

  def thrown(**values) = MOVING.new(g: EARTH, **values)

  # Where it is part way through, against where the whole-flight formulas say
  # it ends up: two routes to the same place, and the law was told neither
  # that they should agree nor that half way is the top.
  def test_half_way_through_is_half_the_range_and_all_of_the_peak
    half = thrown(u: 20.0, theta_0: 40.deg, k: 0.5)

    assert_in_delta half.solve(:R) / 2, half.solve(:x), 1e-9
    assert_in_delta half.solve(:H), half.solve(:y), 1e-9
    assert_in_delta 0.0, half.solve(:v_y), 1e-9
  end

  def test_at_the_end_it_is_back_on_the_ground_going_down_as_fast_as_it_went_up
    done = thrown(u: 20.0, theta_0: 40.deg, k: 1.0)

    assert_in_delta 0.0, done.solve(:y), 1e-9
    assert_in_delta done.solve(:R), done.solve(:x), 1e-9
    assert_in_delta(-20.0 * Math.sin(40.deg), done.solve(:v_y), 1e-9)
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

    assert_in_delta one.solve(:T) / 4, one.solve(:t), 1e-9
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
end
