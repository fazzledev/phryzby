require "minitest/autorun"
require_relative "../chapters"

# The chapter that names its media rather than numbering them.
class ChoosingTest < Minitest::Test
  def playing = CHOOSING
  def opening = playing.opening
  def reads(**changes) = playing.readouts(opening.merge(**changes)).gsub(%r{</?[^>]+>}, " ")

  AIR = 0
  WATER = 1
  GLASS = 2
  DIAMOND = 3

  def test_a_choice_opens_on_the_one_it_was_given
    assert_equal({ from: AIR, into: GLASS }, opening)
  end

  # The chapter holds the angle itself, so there is no control to open on.
  def test_the_angle_is_fixed_and_not_offered
    assert_in_delta 45.0, playing.posing(**opening).solve(:i).in_degrees, 1e-9
    refute_includes playing.controls, %(data-input="i")
  end

  def test_what_was_chosen_reaches_the_law_as_a_number
    assert_in_delta 1.5, playing.posing(**opening).solve(:mu21), 1e-9
    assert_in_delta 28.1255, playing.posing(**opening).solve(:rr).in_degrees, 1e-3
  end

  def test_the_law_is_told_the_ratio_and_never_the_two_media
    posed = playing.posing(**opening).as_posed

    assert_includes posed.keys, :relative_refractive_index
    refute_includes posed.keys, :refractive_index_of_first_medium
    refute_includes posed.keys, :refractive_index_of_second_medium
  end

  def test_a_choice_offers_every_medium_by_name
    offered = playing.controls
                     .scan(%r{<input type="radio" name="from"[^>]*><span>([^<]+)</span>}).flatten

    assert_equal REFRACTIVE_MEDIA.keys, offered
  end

  def test_and_takes_exactly_one_of_them_per_choice
    taken = playing.controls.scan(/<input type="radio" name="(\w+)"[^>]*checked>/).flatten

    assert_equal %w[from into], taken
  end

  def test_and_it_is_the_one_the_chapter_opened_on
    assert_includes playing.controls, %(name="from" data-input="from" value="#{AIR}" checked)
    assert_includes playing.controls, %(name="into" data-input="into" value="#{GLASS}" checked)
  end

  def test_into_a_denser_medium_it_bends_toward_the_normal
    assert_includes reads, "toward the normal"
  end

  def test_out_of_one_it_bends_away
    assert_includes reads(from: WATER, into: AIR), "away from the normal"
  end

  # Far enough out of a dense one and nothing crosses at all, which the next
  # chapter is about.
  def test_and_far_enough_out_of_one_it_does_not_leave
    assert_includes reads(from: DIAMOND, into: AIR), "no refracted ray    yes"
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
