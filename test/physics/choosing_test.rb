require "minitest/autorun"
require_relative "../chapters"

# The chapter that names its media rather than numbering them.
class ChoosingTest < Minitest::Test
  def playing = CHOOSING
  def opening = playing.opening
  def reads(**changes) = playing.readouts(opening.merge(**changes)).gsub(%r{</?[^>]+>}, " ")

  AIR = 0
  GLASS = 2
  DIAMOND = 3

  def test_a_choice_opens_on_the_one_it_was_given
    assert_equal({ i: 30.deg, from: AIR, into: GLASS }, opening)
  end

  def test_what_was_chosen_reaches_the_law_as_a_number
    assert_in_delta 1.5, playing.posing(**opening).solve(:mu21), 1e-9
    assert_in_delta 19.4712, playing.posing(**opening).solve(:rr).in_degrees, 1e-3
  end

  def test_the_law_is_told_the_ratio_and_never_the_two_media
    posed = playing.posing(**opening).as_posed

    assert_includes posed.keys, :relative_refractive_index
    refute_includes posed.keys, :refractive_index_of_first_medium
    refute_includes posed.keys, :refractive_index_of_second_medium
  end

  def test_a_chosen_slider_reads_out_its_name
    assert_includes playing.controls, ">air</output>"
    assert_includes playing.controls, ">glass</output>"
  end

  def test_and_steps_one_medium_at_a_time
    field = playing.controls[/<input type="range" id="from"[^>]*>/]

    assert_includes field, 'min="0"'
    assert_includes field, "max=\"#{MEDIA.size - 1}\""
    assert_includes field, 'step="1"'
  end

  def test_into_a_denser_medium_it_bends_toward_the_normal
    assert_includes reads, "toward the normal"
  end

  def test_out_of_one_it_bends_away
    assert_includes reads(from: DIAMOND, into: AIR, i: 10.deg), "away from the normal"
  end

  def test_and_between_two_alike_it_does_not_bend
    assert_includes reads(from: GLASS, into: GLASS), "not at all"
  end

  def test_the_media_are_named_in_the_picture_and_never_numbered
    drawn = playing.picture(opening.merge(from: AIR, into: DIAMOND), settled: {})
    named = drawn.scan(%r{<text[^>]*>([^<]+)</text>}).flatten

    assert_includes named, "air"
    assert_includes named, "diamond"
    refute(named.any? { |text| text.start_with?("μ") })
  end

  def test_the_denser_of_the_two_is_still_the_more_shaded
    thin, thick = playing.picture(opening.merge(from: AIR, into: DIAMOND), settled: {})
                         .scan(/<rect[^>]*opacity="([\d.]+)"/).flatten.map(&:to_f)

    assert_operator thick, :>, thin
  end
end
