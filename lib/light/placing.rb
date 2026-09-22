module Light
  # Labels are placed together rather than one at a time. Each says where it
  # would like to be and where it would settle for; the first spot that is
  # inside the picture and clear of everything already placed wins, and if a
  # label has no clear spot it takes its first choice rather than vanish.
  class Placing
    LETTER = 6.2
    ABOVE = 8
    BELOW = 3
    EDGE = 2

    def initialize(width, height)
      @width = width
      @height = height
      @taken = []
    end

    def resolve(wanted)
      # Whatever can go anywhere goes after whatever cannot.
      wanted.sort_by { |want| want[:last] ? 1 : 0 }.map do |want|
        spot = want[:spots].find { |place| free?(box(place, want[:text])) } || want[:spots].first
        @taken << box(spot, want[:text])

        drawn(spot, want)
      end
    end

    private

    def box((x, y, anchor), text)
      wide = text.length * LETTER
      left = case anchor
             when "end" then x - wide
             when "middle" then x - wide / 2
             else x
             end

      [ left, y - ABOVE, left + wide, y + BELOW ]
    end

    def free?(box)
      inside?(box) && @taken.none? { |taken| overlaps?(taken, box) }
    end

    def inside?((x0, y0, x1, y1))
      x0 >= EDGE && y0 >= EDGE && x1 <= @width - EDGE && y1 <= @height - EDGE
    end

    def overlaps?(one, other)
      one[0] < other[2] && other[0] < one[2] && one[1] < other[3] && other[1] < one[3]
    end

    def drawn((x, y, anchor), want)
      %(<text x="#{x.round(1)}" y="#{y.round(1)}" fill="#{want[:colour]}" ) +
        %(text-anchor="#{anchor}" font-family="ui-monospace, monospace" ) +
        %(font-size="11">#{want[:text]}</text>)
    end
  end
end
