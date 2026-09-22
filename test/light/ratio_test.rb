require "minitest/autorun"
require_relative "../chapters"

# The chapter that puts the held ratio on a slider, and adds no law to do it.
class RatioTest < Minitest::Test
  def playing = RATIOED
  def opening = playing.opening
  READING = %r{<span>([^<]*)</span>.*?class="val">([^<]*)</span>}

  def says(**changes) = playing.readouts(opening.merge(**changes)).scan(READING).to_h
  def drawn(**changes) = playing.picture(opening.merge(**changes), settled: {})

  # Water into air to within a step of the slider, which is as near as a
  # number the reader can move gets to one the book held.
  def test_it_opens_on_the_crossing_the_chapters_before_it_held
    assert_in_delta 1.0 / 1.33, opening.fetch(:mu21), 0.01
    assert_equal "48.59°", says.fetch("critical")
    assert_equal "41.81°", says.fetch("angle of refraction")
  end

  def test_the_ratio_is_the_law_s_own_quantity_and_no_law_was_added
    assert_includes Refraction.quantities.keys, :mu21
    assert_equal [ :snells_law ], Refraction.equations.keys
    assert_includes playing.controls, %(data-input="mu21")
  end

  # Above one it bends toward the normal and there is no angle it cannot
  # cross at; below one it bends away and eventually cannot cross at all.
  def test_the_ratio_alone_decides_which_way_and_whether
    assert_equal "—", says(mu21: 1.5).fetch("critical")
    assert_equal "19.47°", says(mu21: 1.5).fetch("angle of refraction")
    assert_equal "yes", says(mu21: 0.4).fetch("no refracted ray")
  end

  def test_and_at_one_the_ray_goes_straight_on
    assert_equal "30.00°", says(mu21: 1.0).fetch("angle of refraction")
  end

  # The ratio says which of the two is the denser and by how much, and that is
  # all the shading can honestly say.
  def test_the_denser_side_is_the_shaded_one_whichever_side_it_is
    assert_equal [ [ "0", "0.117" ] ], bands(drawn)
    assert_equal [ [ "100", "0.166" ] ], bands(drawn(mu21: 1.5))
    assert_empty bands(drawn(mu21: 1.0))
  end

  # The same number shades the same: a ratio of 1.33 looks the way water looks
  # against air, because it is what water is against air.
  def test_and_by_as_much_as_the_chapters_that_name_their_media
    assert_equal bands(drawn(mu21: 1.33)).first.last,
                 INDEXED.picture(INDEXED.opening.merge(mu1: 1.0, mu2: 1.33), settled: {})
                        .scan(/<rect[^>]*y="100"[^>]*opacity="([\d.]+)"/).flatten.first
  end

  def bands(svg) = svg.scan(/<rect[^>]*y="(\d+)"[^>]*opacity="([\d.]+)"/)

  # Nothing here knows which two media make the number, so the picture names
  # no medium at all.
  def test_the_picture_names_a_surface_and_not_two_media
    named = drawn.scan(%r{<text[^>]*>([^<]+)</text>}).flatten

    assert_includes named, "surface"
    refute(named.any? { |text| REFRACTIVE_MEDIA.key?(text) || text.start_with?("μ") })
  end
end
