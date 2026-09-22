require "minitest/autorun"
require_relative "../../lib/playground/light/refraction"

class PictureTest < Minitest::Test
  # Fresh each time: the placer remembers where labels settled, and a test
  # should not depend on what the test before it drew.
  def drawn(**changes)
    playing = Physics.playground
    playing.picture(playing.opening.merge(**changes), settled: {})
  end

  # A ray is counted by its arrowhead: the arcs marking angles are paths too.
  def rays(svg) = svg.scan(/<path[^>]*z"/).size

  def arcs(svg) = svg.scan(/<path[^>]*fill="none"/).size

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

  WIDE = 6.2

  def labels(svg)
    svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*text-anchor="(\w+)"[^>]*>([^<]+)</text>})
       .map do |x, y, anchor, text|
      room = text.length * WIDE
      left = case anchor
             when "end" then x.to_f - room
             when "middle" then x.to_f - room / 2
             else x.to_f
             end

      [ text, left, y.to_f - 8, left + room, y.to_f + 3 ]
    end
  end

  def test_no_two_labels_sit_on_each_other_at_any_angle
    clashes = (1..179).sum do |half|
      labels(drawn(i: (half / 2.0).deg)).combination(2).count do |one, other|
        one[1] < other[3] && other[1] < one[3] && one[2] < other[4] && other[2] < one[4]
      end
    end

    assert_equal 0, clashes
  end

  def test_no_label_runs_off_the_picture_at_any_angle
    escaped = (1..179).sum do |half|
      labels(drawn(i: (half / 2.0).deg))
        .count { |_, x0, y0, x1, y1| x0.negative? || y0.negative? || x1 > 300 || y1 > 200 }
    end

    assert_equal 0, escaped
  end

  def test_a_mark_is_drawn_only_when_there_is_such_an_angle
    assert_includes drawn(mu1: 1.5, mu2: 1.0), "critical 41.81°"
    refute_includes drawn(mu1: 1.0, mu2: 1.5), "critical"
  end

  # It names a line that never moves, so it never moves either.
  def test_the_normal_stays_where_it_is_whatever_the_rays_do
    everywhere = [ 1, 8, 30, 60, 89 ].map do |degrees|
      labels(drawn(i: degrees.deg)).find { |text,| text == "normal" }[1..2].map(&:round)
    end

    assert_equal [ everywhere.first ], everywhere.uniq
  end

  def test_a_label_pushed_aside_stays_put_rather_than_hunting
    playing = Physics.playground
    seen = (1..179).map do |half|
      svg = playing.picture(playing.opening.merge(mu1: 1.5, mu2: 1.0, i: (half / 2.0).deg))
      svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*>(critical[^<]*)</text>}).first&.first(2)
    end.compact.map { |x, y| [ x.to_f, y.to_f ] }

    leaps = seen.each_cons(2).count { |a, b| Math.hypot(b[0] - a[0], b[1] - a[1]) > 12 }

    assert_equal 0, leaps
  end
  NORMAL = 150

  def anchored(svg)
    svg.scan(%r{<text x="([-\d.]+)"[^>]*text-anchor="(\w+)"[^>]*>([^<]+)</text>})
       .to_h { |x, anchor, text| [ text, [ x.to_f, anchor ] ] }
  end

  # Two nearly vertical rays point almost the same way, so their labels are
  # thrown aside rather than left to follow them. The geometry is a mirror
  # image, so the throw has to be too.
  def test_two_shallow_rays_are_thrown_aside_equally
    playing = Physics.playground
    placed = anchored(playing.picture(playing.opening.merge(i: 5.deg), settled: {}))

    assert_in_delta NORMAL - placed.fetch("incident").first,
                    placed.fetch("reflected").first - NORMAL, 0.5
  end

  def test_and_far_enough_aside_to_be_read
    playing = Physics.playground
    placed = anchored(playing.picture(playing.opening.merge(i: 5.deg), settled: {}))

    assert_operator placed.fetch("reflected").first - placed.fetch("incident").first, :>, 24
  end

  def shades(svg) = svg.scan(/<rect[^>]*opacity="([\d.]+)"/).flatten.map(&:to_f)

  def test_the_denser_medium_is_the_more_shaded
    upper, lower = shades(drawn(mu1: 1.0, mu2: 1.5))

    assert_operator lower, :>, upper
  end

  def test_and_it_follows_the_media_round
    upper, lower = shades(drawn(mu1: 1.5, mu2: 1.0))

    assert_operator upper, :>, lower
  end

  def test_the_shade_rises_with_the_index
    thin, = shades(drawn(mu1: 1.0, mu2: 1.5))
    thick, = shades(drawn(mu1: 2.4, mu2: 1.5))

    assert_operator thick, :>, thin
  end

  def test_two_media_alike_are_shaded_alike
    upper, lower = shades(drawn(mu1: 1.4, mu2: 1.4))

    assert_in_delta upper, lower, 1e-9
  end

  def test_an_angle_is_marked_only_where_it_is_asked_for
    assert_equal 2, arcs(drawn)
  end

  def test_and_the_arc_is_labelled_with_the_angle_it_sweeps
    assert_includes drawn(i: 42.deg), "42.0\u00b0"
  end

  def test_an_angle_that_has_no_ray_is_not_marked
    assert_equal 1, arcs(drawn(mu1: 1.5, mu2: 1.0, i: 60.deg))
  end

  # Notation, drawn without a scenario behind it: none of it asks the laws
  # anything.
  def bare(&drawing)
    picture = Light::Picture.new(nil)
    picture.instance_eval(&drawing)
    picture.to_svg
  end

  HATCHING = %r{<line x1="([\d.]+)" y1="100" x2="([\d.]+)" y2="108"}

  def test_a_mirror_is_hatched_behind_its_face_rather_than_filled
    drawn = bare { mirror }

    refute_includes drawn, "<rect"
    assert_equal [ -Light::Picture::HATCH_LEAN ],
                 drawn.scan(HATCHING).map { |x1, x2| x2.to_f - x1.to_f }.uniq
  end

  def test_and_the_hatching_runs_the_whole_width_of_it
    along = bare { mirror }.scan(HATCHING).map { |x1,| x1.to_f }

    assert_operator along.first, :<, Light::Picture::HATCH
    assert_operator along.last, :>, Light::Picture::WIDTH - 2 * Light::Picture::HATCH
  end

  def test_a_surface_that_is_not_a_mirror_is_not_hatched
    assert_empty bare { surface }.scan(HATCHING)
  end

  ONE_LINE = %r{<line [^>]*stroke="var\((--[\w-]+)\)" stroke-width="([\d.]+)"/>}
  CONSTRUCTION = %r{<g stroke-dasharray="[^"]+">#{ONE_LINE.source}#{ONE_LINE.source}</g>}

  # The normal and the critical mark both run through shading that can be
  # nearly their own colour, so each is drawn twice: paper under, line over.
  def test_every_construction_line_carries_paper_with_it
    drawn = bare do
      surface
      mark "critical", arriving_at: 0.73
    end
    lines = drawn.scan(CONSTRUCTION)

    assert_equal 2, lines.size
    lines.each do |under, wide, over, thin|
      assert_equal "--paper", under
      refute_equal "--paper", over
      assert_operator wide.to_f, :>, thin.to_f
    end
  end

  def bands(svg) = svg.scan(%r{>(\u03bc[^<]*)</text>}).flatten

  def test_a_band_is_named_when_its_index_is_one_anybody_knows
    assert_equal [ "\u03bc\u2081 water", "\u03bc\u2082 diamond" ], bands(drawn(mu1: 1.33, mu2: 2.42))
  end

  def test_and_is_only_its_symbol_between_them
    assert_equal [ "\u03bc\u2081 air", "\u03bc\u2082" ], bands(drawn(mu1: 1.0, mu2: 2.0))
  end
end
