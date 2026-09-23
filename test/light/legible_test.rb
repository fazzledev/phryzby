require "minitest/autorun"
require_relative "../chapters"

# Every label the book draws, in every position its controls can reach: none
# of them off the picture, none of them on top of another.
class LegibleTest < Minitest::Test
  LETTER = 6.2
  ABOVE = 8
  BELOW = 3

  def boxed(x, y, anchor, text)
    wide = text.length * LETTER
    left = case anchor
           when "end" then x - wide
           when "middle" then x - wide / 2.0
           else x
           end

    [ left, y - ABOVE, left + wide, y + BELOW ]
  end

  def hits?(one, other)
    one[0] < other[2] && other[0] < one[2] && one[1] < other[3] && other[1] < one[3]
  end

  def labels(svg)
    svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*text-anchor="(\w+)"[^>]*>([^<]+)</text>})
       .map { |x, y, anchor, text| [ text, boxed(x.to_f, y.to_f, anchor, text) ] }
  end

  def legible(what, svg)
    placed = labels(svg)

    off = placed.select { |_, box| box[0] < 0 || box[1] < 0 || box[2] > 300 || box[3] > 200 }
    assert_empty off.map(&:first), "#{what}: off the picture"

    piled = placed.combination(2).select { |(_, one), (_, other)| hits?(one, other) }
    assert_empty piled.map { |(one, _), (other, _)| "#{one} / #{other}" }, "#{what}: piled up"
  end

  def sweeping(playing, name, **held)
    (1..89).step(4) do |degrees|
      at = playing.opening.merge(**held)
      at = at.merge(i: degrees.deg) if at.key?(:i)
      legible("#{name} at #{degrees}°", playing.picture(at, settled: {}))
    end
  end

  def test_the_chapters_that_sweep_an_angle_stay_legible
    { "1.3" => BENDING, "1.4" => OUT_OF_WATER, "1.5" => INTERNAL, "1.6" => CRITICAL }
      .each { |name, playing| sweeping(playing, name) }
  end

  # The steeper the mark the tighter the corner it points into, and a long
  # red label has to find somewhere else to stand.
  def test_the_chapters_that_change_media_stay_legible
    REFRACTIVE_MEDIA.each_value.with_index do |index, at|
      legible("1.7 from #{at}", INTO_AIR.picture(INTO_AIR.opening.merge(from: at), settled: {}))
      legible("1.9 mu1 #{index}", INDEXED.picture(INDEXED.opening.merge(mu1: index), settled: {}))
      sweeping(DRAWING, "drawing mu1 #{index}", mu1: index)
    end
  end

  def test_the_chapter_that_sweeps_the_ratio_stays_legible
    [ 0.25, 0.4, 0.5, 0.75, 1.0, 1.5, 2.5, 4.0 ].each do |ratio|
      legible("1.8 at #{ratio}", RATIOED.picture(RATIOED.opening.merge(mu21: ratio), settled: {}))
    end
  end
end
