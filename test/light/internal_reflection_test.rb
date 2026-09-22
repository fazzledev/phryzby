require "minitest/autorun"
require_relative "../chapters"

# The chapter where a boundary stops being a mirror or a window.
class InternalReflectionTest < Minitest::Test
  def playing = INTERNAL
  def opening = playing.opening
  def reads(**changes) = playing.readouts(opening.merge(**changes)).gsub(%r{</?[^>]+>}, " ")
  def drawn(**changes) = playing.picture(opening.merge(**changes), settled: {})
  def rays(svg) = svg.scan(/<path[^>]*z"/).size

  AIR = 0
  WATER = 1
  GLASS = 2
  SILICON = 5

  def test_one_ray_arrives_and_two_leave
    assert_equal 3, rays(drawn)
  end

  def test_the_side_you_arrive_from_names_the_reflection
    assert_includes reads, "internal"
    assert_includes reads(from: AIR, into: GLASS), "external"
  end

  def test_and_between_two_alike_it_is_neither
    assert_includes reads(from: GLASS, into: GLASS), "neither"
  end

  # Held at 20°, only the steepest drops in index have no way out, and there
  # the one that turns back is the only one left.
  def test_most_of_the_denser_pairs_still_let_something_across
    assert_includes reads(from: GLASS, into: AIR), "no refracted ray    no"
    assert_includes reads(from: SILICON, into: AIR), "no refracted ray    yes"
    assert_equal 2, rays(drawn(from: SILICON, into: AIR))
    assert_includes drawn(from: SILICON, into: AIR), "all of it turns back"
  end

  # Whichever way it is crossed, the law of reflection answers the same.
  def test_the_reflected_ray_leaves_at_the_angle_it_arrived_at
    [ [ GLASS, AIR ], [ AIR, WATER ] ].each do |from, into|
      here = playing.posing(**opening.merge(from: from, into: into))

      assert_in_delta 20.0, here.solve(:rl).in_degrees, 1e-9
    end
  end
end
