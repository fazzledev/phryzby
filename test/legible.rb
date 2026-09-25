# Every label the book draws, in every position its controls can reach: none
# of them off the picture, none of them on top of another. The rule is the
# same whatever is being drawn, so both subjects are held to it here.
module Legible
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
end
