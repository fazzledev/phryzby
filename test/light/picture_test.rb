require "minitest/autorun"
require_relative "../../lib/shown/light/refraction"

class PictureTest < Minitest::Test
  def drawn(**changes)
    showing = Crossing.showing_of
    showing.picture(showing.opening.merge(**changes))
  end

  def rays(svg) = svg.scan(/<path/).size

  def test_every_ray_is_drawn_when_there_is_one
    assert_equal 3, rays(drawn)
  end

  def test_a_ray_that_does_not_exist_is_not_drawn
    trapped = drawn(mu1: 1.5, mu2: 1.0, i: 60.deg)

    assert_equal 2, rays(trapped)
    assert_includes trapped, "no refracted ray"
  end

  def test_the_note_stays_away_while_its_condition_is_false
    refute_includes drawn, "no refracted ray"
  end

  def test_the_media_are_labelled_the_way_the_law_writes_them
    assert_includes drawn, "μ₁"
    assert_includes drawn, "μ₂"
  end

  def test_it_draws_from_the_law_rather_than_from_numbers_given
    refute_equal drawn, drawn(i: 80.deg)
  end
end
