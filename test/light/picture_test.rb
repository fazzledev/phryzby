require "minitest/autorun"
require_relative "../../lib/shown/light/refraction"

class PictureTest < Minitest::Test
  def drawn(**changes)
    showing = Physics.shown.showing_of
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
    showing = Physics.shown.showing_of
    seen = (1..179).map do |half|
      svg = showing.picture(showing.opening.merge(mu1: 1.5, mu2: 1.0, i: (half / 2.0).deg))
      svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*>(critical[^<]*)</text>}).first&.first(2)
    end.compact.map { |x, y| [ x.to_f, y.to_f ] }

    leaps = seen.each_cons(2).count { |a, b| Math.hypot(b[0] - a[0], b[1] - a[1]) > 12 }

    assert_equal 0, leaps
  end
end
