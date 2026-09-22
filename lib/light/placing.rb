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

    def initialize(width, height, settled = {})
      @width = width
      @height = height
      @settled = settled
      @taken = []
    end

    # Where each label ended up, so the next picture can put it back.
    attr_reader :settled

    def resolve(wanted)
      kept = {}

      # What does not move claims its place first, so it is never the thing
      # shoved aside by something sliding past.
      drawn = wanted.sort_by { |want| want[:fixed] ? 0 : 1 }.map do |want|
        spot = choose(want)
        kept[want[:text]] = spot
        @taken << box(spot, want[:text])

        drawn(spot, want)
      end

      @settled = kept
      drawn
    end

    private

    # Home if it is free, otherwise wherever it was last time if that still is,
    # and only then somewhere new. A label that has been pushed aside stays put
    # rather than hunting, and comes back the moment it can.
    def choose(want)
      home, *rest = want[:spots]
      return home if free?(box(home, want[:text]))

      held = @settled[want[:text]]
      return held if held && rest.include?(held) && free?(box(held, want[:text]))

      rest.find { |place| free?(box(place, want[:text])) } || home
    end

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

    # Labels keep clear of each other but not of the picture, so each carries a
    # little of the paper with it and stays legible over a ray it crosses.
    def drawn((x, y, anchor), want)
      %(<text x="#{x.round(1)}" y="#{y.round(1)}" fill="#{want[:colour]}" ) +
        %(text-anchor="#{anchor}" font-family="ui-monospace, monospace" font-size="11" ) +
        %(stroke="var(--paper)" stroke-width="2.5" paint-order="stroke">#{want[:text]}</text>)
    end
  end
end
