require "minitest/autorun"
require_relative "../chapters"

# The chapter that draws the ray that does not cross.
class InternalReflectionTest < Minitest::Test
  def playing = INTERNAL
  def reads(**changes)
    playing.readouts(playing.opening.merge(**changes)).gsub(%r{</?[^>]+>}, " ")
  end

  def drawn(**changes) = playing.picture(playing.opening.merge(**changes), settled: {})
  def rays(svg) = svg.scan(/<path[^>]*z"/).size

  def test_one_ray_arrives_and_two_leave
    assert_equal 3, rays(drawn)
  end

  # The same water and air as the chapter before it, answered by both laws.
  def test_it_crosses_the_way_the_chapter_before_said_it_would
    assert_includes reads, "41.68°"
    assert_includes reads(i: 10.deg), "13.35°"
  end

  def test_and_the_one_that_turns_back_leaves_at_the_angle_it_arrived_at
    assert_in_delta 30.0, playing.posing(**playing.opening).solve(:rl).in_degrees, 1e-9
    assert_in_delta 70.0, playing.posing(**playing.opening.merge(i: 70.deg)).solve(:rl).in_degrees, 1e-9
  end

  # Past the angle the crossing ray is gone and this one is not, which is the
  # whole of what the chapter says.
  def test_past_the_angle_it_is_the_only_one_left
    trapped = drawn(i: 48.8.deg)

    assert_equal 2, rays(trapped)
    assert_includes trapped, "all of it turns back"
    assert_includes reads(i: 48.8.deg), "angle of reflection  rl  48.80°"
    assert_includes reads(i: 48.8.deg), "angle of refraction  rr  —"
  end
end
