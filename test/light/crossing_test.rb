require "minitest/autorun"
require_relative "../chapters"

# The two chapters that hold a pair of media and vary only the angle.
class CrossingTest < Minitest::Test
  def reads(playing, **changes)
    playing.readouts(playing.opening.merge(**changes)).gsub(%r{</?[^>]+>}, " ")
  end

  def drawn(playing, **changes)
    playing.picture(playing.opening.merge(**changes), settled: {})
  end

  def test_into_water_the_refracted_angle_is_the_smaller_one
    assert_includes reads(BENDING), "22.08°"
    assert_includes reads(BENDING, i: 60.deg), "40.63°"
  end

  def test_out_of_water_it_is_the_larger_one
    assert_includes reads(OUT_OF_WATER), "41.68°"
    assert_includes reads(OUT_OF_WATER, i: 10.deg), "13.35°"
  end

  # Going in there is always a way across, and edge on it still only reaches
  # the angle that coming out cannot get past.
  def test_no_angle_into_water_is_too_steep
    assert_includes reads(BENDING, i: 89.5.deg), "48.75°"
    refute_includes reads(BENDING, i: 89.5.deg), "—"
  end

  def test_past_the_angle_where_it_lies_flat_there_is_no_way_out
    assert_includes reads(OUT_OF_WATER, i: 48.75.deg), "89.41°"
    assert_includes reads(OUT_OF_WATER, i: 48.8.deg), "no refracted ray    yes"
    assert_includes drawn(OUT_OF_WATER, i: 48.8.deg), "no refracted ray"
  end

  # Each chapter names its own two media, and holds them.
  def test_the_bands_are_named_and_the_chapter_holds_them
    assert_equal [ "air", "water" ], banded(drawn(BENDING))
    assert_equal [ "water", "air" ], banded(drawn(OUT_OF_WATER))
    assert_empty BENDING.controls.scan(/type="radio"/)
  end

  def banded(svg)
    svg.scan(%r{<text[^>]*>([^<]+)</text>}).flatten & REFRACTIVE_MEDIA.keys
  end
end
