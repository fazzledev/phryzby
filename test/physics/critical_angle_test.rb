require "minitest/autorun"
require_relative "../chapters"

# The chapter with no law of its own: the angle is Snell asked backwards.
class CriticalAngleTest < Minitest::Test
  def playing = CRITICAL
  def opening = playing.opening
  READING = %r{<span>([^<]*)</span>.*?class="val">([^<]*)</span>}

  # Each reading by the name beside it.
  def says(**changes) = playing.readouts(opening.merge(**changes)).scan(READING).to_h

  def test_it_holds_the_crossing_the_chapters_before_it_held
    assert_equal({ i: 30.deg }, opening)
    assert_in_delta 1.0 / 1.33, playing.posing(**opening).solve(:mu21), 1e-9
  end

  def test_nothing_states_the_critical_angle
    said = Refraction.equations.values.map(&:to_s).join(" ")

    refute_includes said, "asin"
    assert_equal [ :snells_law ], Refraction.equations.keys
  end

  def test_and_it_is_asked_rather_than_stated
    asked = playing.posing(**opening).asking(:i, rr: 90.deg)

    assert_in_delta Math.asin(1.0 / 1.33), asked, 1e-9
    assert_in_delta 48.7535, asked.in_degrees, 1e-3
  end

  def test_the_angle_it_names_is_the_one_the_sliding_found
    assert_equal "48.75°", says.fetch("critical")
    assert_equal "no", says(i: 48.7.deg).fetch("no refracted ray")
    assert_equal "yes", says(i: 48.8.deg).fetch("no refracted ray")
  end

  def test_and_it_stands_in_the_picture_whatever_the_ray_is_doing
    [ 30, 60 ].each do |degrees|
      assert_includes playing.picture(opening.merge(i: degrees.deg), settled: {}),
                      "critical 48.75°"
    end
  end
end
