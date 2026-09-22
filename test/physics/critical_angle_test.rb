require "minitest/autorun"
require_relative "../chapters"

# The chapter with no law of its own: the angle is Snell asked backwards.
class CriticalAngleTest < Minitest::Test
  def playing = CRITICAL
  def opening = playing.opening
  READING = %r{<span>([^<]*)</span>.*?class="val">([^<]*)</span>}

  # Each reading by the name beside it.
  def says(**changes) = playing.readouts(opening.merge(**changes)).scan(READING).to_h

  AIR = 0
  GLASS = 2
  DIAMOND = 3

  def test_it_opens_leaving_the_denser_medium
    assert_equal({ i: 30.deg, from: GLASS, into: AIR }, opening)
  end

  def test_nothing_states_the_critical_angle
    said = Refraction.equations.values.map(&:to_s).join(" ")

    refute_includes said, "asin"
    assert_equal [ :snells_law ], Refraction.equations.keys
  end

  def test_and_it_is_asked_rather_than_stated
    asked = playing.posing(**opening).asking(:i, rr: 90.deg)

    assert_in_delta Math.asin(1.0 / 1.5), asked, 1e-9
    assert_in_delta 41.8103, asked.in_degrees, 1e-3
  end

  def test_the_denser_the_medium_the_sooner_it_traps
    assert_equal "41.81°", says.fetch("critical")
    assert_equal "24.41°", says(from: DIAMOND).fetch("critical")
  end

  def test_going_the_other_way_there_is_no_such_angle
    said = says(from: AIR, into: GLASS)

    assert_equal "—", said.fetch("critical")
    assert_equal "19.47°", said.fetch("angle of refraction")
  end

  def test_past_it_no_ray_gets_out
    assert_equal "no", says(i: 41.deg).fetch("no refracted ray")
    assert_equal "yes", says(i: 42.deg).fetch("no refracted ray")
  end

  def test_the_picture_marks_it_where_the_angle_exists
    assert_includes playing.picture(opening, settled: {}), "critical 41.81°"
    refute_includes playing.picture(opening.merge(from: AIR, into: GLASS), settled: {}), "critical"
  end
end
