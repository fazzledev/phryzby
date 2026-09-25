require "minitest/autorun"
require_relative "../chapters"

# The chapter that draws the ray that does not cross.
class InternalReflectionTest < Minitest::Test
  def playing = INTERNAL
  # The letter beside each reading is set as maths now, so a subscript is two
  # elements rather than two characters. Put it back the way the law spells
  # it before flattening the rest.
  def reads(**changes)
    playing.readouts(playing.opening.merge(**changes))
           .gsub(%r{<msub><mi>([^<]*)</mi><mi>([^<]*)</mi></msub>}, '\1_\2')
           .gsub(%r{</?(?:math|mrow|mi)>}, "")
           .gsub(%r{</?[^>]+>}, " ")
  end

  def drawn(**changes) = playing.picture(playing.opening.merge(**changes), settled: {})
  def rays(svg) = svg.scan(/<path class="head"/).size

  # It opens where the chapter before it ended: past the angle, with nothing
  # getting out and the surface behaving as the mirror of 1.2 did.
  def test_it_opens_on_the_ray_that_is_all_that_is_left
    assert_equal 2, rays(drawn)
    assert_includes drawn, "all of it turns back"
    assert_includes reads, "angle of reflection  r_l  60.00°"
    assert_includes reads, "angle of refraction  r_r  —"
  end

  # Slide back down and the crossing one is there again beside it, because
  # some of the light turns back at every angle and not only past this one.
  def test_and_below_it_one_ray_arrives_and_two_leave
    assert_equal 3, rays(drawn(i: 30.deg))
    assert_includes reads(i: 30.deg), "41.68°"
    assert_includes reads(i: 10.deg), "13.35°"
  end

  def test_the_one_that_turns_back_leaves_at_the_angle_it_arrived_at
    [ 10, 30, 60, 80 ].each do |degrees|
      here = playing.posing(**playing.opening.merge(i: degrees.deg))

      assert_in_delta degrees, here.solve(:r_l).in_degrees, 1e-9
    end
  end

  # The angle it turns on is water's, named two chapters ago.
  def test_the_turn_is_at_the_angle_the_book_named
    assert_equal 3, rays(drawn(i: 48.7.deg))
    assert_equal 2, rays(drawn(i: 48.8.deg))
  end
end
