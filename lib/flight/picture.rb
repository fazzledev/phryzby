require_relative "../physics"
require_relative "../drawing/placing"

module Flight
  # A throw, drawn to scale. The frame is as wide as the fastest throw the
  # chapter allows can go, so nothing ever leaves the picture and the arc
  # growing means the throw grew — not that the drawing zoomed out.
  class Picture
    WIDTH = 300
    HEIGHT = 200
    GROUND = 172
    START = 20
    REACH = 262
    STEPS = 48
    HEAD = 7

    # `across` is how much ground is in view, in metres. It is the chapter's
    # to choose and it does not move: a frame cut to fit whatever was thrown
    # would draw every throw the same size, and then nothing the reader did
    # would show.
    def initialize(scenario, chosen = {}, across: nil)
      @scenario = scenario
      @chosen = chosen
      @across = across
      @shapes = []
      @wanted = []
    end

    # The ground it is thrown from and lands back on. Everything else is
    # measured off this line.
    # The ground, and how much of it is in the picture — which is fixed, so it
    # is a ruler as much as a label: everything drawn above it is measured
    # against this one number.
    def ground(called: nil)
      @shapes.unshift(turf)
      # Written on the ground, because that is what it measures, and as low
      # down it as a label is allowed to sit: everything above the line is the
      # throw's. Nothing else is down here — a mark on the ground can be read
      # from just above it, and this cannot be read anywhere else at all.
      want(called || format("%g m of ground", span.round),
           [ [ WIDTH / 2, GROUND + 23, "middle" ] ], fixed: true)
    end

    # The whole throw: the arc it flies, the angle it left at, and the hand
    # it left from. A throw whose angle a control sets can be swung by hand.
    #
    # It goes unnamed unless a chapter asks. A picture of light has to tell
    # three rays apart; this one has a single curve in it, and a label on the
    # only thing there says nothing the picture did not.
    def flight(called = nil, leaving_at:)
      turned = value(leaving_at)
      return if turned.nil?

      @dragged = leaving_at if draggable?(leaving_at)
      @shapes.push(arc(turned), swept(turned), launched(turned), thrown)
      want(called, aloft(turned), colour: "var(--light)") if called
    end

    PUSH = 160

    # What it left the hand with, as an arrow: the way it was going and how
    # fast. It is drawn against the picture rather than against the ground —
    # the fastest the chapter allows reaches PUSH across, whatever the view —
    # so standing back does not shrink it away to nothing along with the
    # throw. It says how hard, not how far.
    def launched(turned)
      speed = value(:u)
      return "" if speed.nil? || speed <= 0

      long = PUSH * speed / fastest
      tip = [ (START + Math.cos(turned) * long).round(2),
              (GROUND - Math.sin(turned) * long).round(2) ]
      wing = lambda do |swing|
        [ (tip[0] - Math.cos(turned + swing) * HEAD).round(2),
          (tip[1] + Math.sin(turned + swing) * HEAD).round(2) ].join(",")
      end

      %(<line x1="#{START}" y1="#{GROUND}" x2="#{tip[0]}" y2="#{tip[1]}" ) +
        %(stroke="var(--ink)" stroke-width="1.6"/>) +
        %(<path class="head" d="M #{tip.join(',')} L #{wing.call(0.42)} L #{wing.call(-0.42)} z" ) +
        %(fill="var(--ink)"/>).tap { quickly(speed, turned, long) }
    end

    # How fast it left, written alongside the arrow on its outer side — the
    # side the throw curves away from, so the words are never over the arc
    # they belong to the start of.
    #
    # The arrow itself may run clean off the picture; the words naming it may
    # not, so each spot is brought back inside far enough to be read.
    def quickly(speed, turned, long)
      # Outside first, and if the picture has no room out there, inside —
      # each anchored so the words grow away from the arrow rather than back
      # across it.
      outside = [ [ 0.55, 12 ], [ 0.8, 12 ], [ 0.3, 12 ], [ 0.55, 22 ], [ 1.0, 14 ],
                  [ 0.55, 32 ] ].flat_map { |part, aside| [ [ part, aside, "end" ],
                                                            [ part, aside, "middle" ] ] }
      inside = [ [ 0.55, -14 ], [ 0.85, -14 ], [ 0.3, -14 ], [ 1.05, -18 ] ]
               .map { |part, aside| [ part, aside, "start" ] }

      want(format("%.1f m/s", speed),
           (outside + inside).map { |part, aside, anchor| beside(turned, long, part, aside, anchor) },
           colour: "var(--ink-mid)")
    end

    # A spot a little way along the arrow and a little way off it, on whichever
    # side was asked for. How far along is capped, because the arrow may be
    # longer than the picture and the words have to stay in it.
    def beside(turned, long, part, aside, anchor)
      out = turned + Math::PI / 2
      along = long * part

      [ START + Math.cos(turned) * along + Math.cos(out) * aside,
        (GROUND - Math.sin(turned) * along - Math.sin(out) * aside).clamp(20.0, GROUND - 6.0),
        anchor ]
    end

    # How far it got, marked on the ground it got there along — unless it got
    # further than the picture does, which on a world that pulls lightly it
    # will. Then all the picture can honestly say is that it went that way.
    def reach(called, name)
      metres = value(name)
      return if metres.nil?

      if along(metres) > WIDTH - 4
        return want("#{called} \u2192",
                    [ [ WIDTH - 6, GROUND - 7, "end" ], [ WIDTH - 6, GROUND - 19, "end" ],
                      [ WIDTH - 6, GROUND + 15, "end" ], [ WIDTH - 6, GROUND - 31, "end" ],
                      [ WIDTH - 6, GROUND - 43, "end" ], [ WIDTH - 6, GROUND - 55, "end" ] ],
                    colour: "var(--light)")
      end

      at = along(metres)
      @shapes.push(dropped(at), tick(at))

      # Just above the line it marks, and off to the side of the arrowhead
      # coming down on it. The room under the line is the ruler's.
      want(called, [ [ at + 11, GROUND - 13, "start" ], [ at - 11, GROUND - 13, "end" ],
                     [ at + 11, GROUND - 25, "start" ], [ at - 11, GROUND - 25, "end" ],
                     [ at, GROUND - 37, "middle" ], [ at, GROUND + 15, "middle" ] ])
    end

    # How high it got, measured where it got there: straight up off the ground
    # to the top of the arc, which is half way along it. A height is a measure
    # up, and was being drawn as a line across — the same shape as the range,
    # which is a measure along. Nothing is marked when the top of the arc is
    # outside the picture, because the measure would have no end in it.
    def apex(called, name)
      metres = value(name)
      reached = value(:r)
      return if metres.nil? || reached.nil?

      top = up(metres)
      at = along(reached / 2)
      return if top < 8 || at > WIDTH - 8

      @shapes.push(risen(at, top))
      middle = (top + GROUND) / 2 - 2
      want(called, [ [ at + 7, middle, "start" ], [ at - 7, middle, "end" ],
                     [ at + 7, top + 14, "start" ], [ at - 7, top + 14, "end" ],
                     [ at + 7, GROUND - 10, "start" ], [ at - 7, GROUND - 10, "end" ],
                     [ at, top - 7, "middle" ], [ at, top - 19, "middle" ],
                     [ at + 20, middle, "start" ], [ at - 20, middle, "end" ],
                     [ at + 20, top - 7, "start" ], [ at - 20, top - 7, "end" ],
                     [ at + 34, middle, "start" ], [ at - 34, middle, "end" ],
                     [ at, top - 31, "middle" ], [ at, top - 43, "middle" ],
                     [ at + 34, top - 19, "start" ], [ at - 34, top - 19, "end" ],
                     [ at + 52, middle, "start" ], [ at - 52, middle, "end" ] ])
    end

    # Where it is part way through, and how it is going: a ring on the arc at
    # that moment, with the arrow it would be carrying there. The arrow is on
    # the throw's own scale, so it can be read against the one at the hand —
    # the same length when it has lost nothing, shorter when it has.
    def now(called = nil)
      out = value(:x)
      up_to = value(:y)
      across = value(:v_x)
      rising = value(:v_y)
      return if [ out, up_to, across, rising ].any?(&:nil?)

      at = [ along(out), up(up_to) ]
      return if at[0] > WIDTH - 4 || at[1] < 4

      @shapes.push(carrying(at, across, rising), ringed(at))
      want(called, beside_the_ring(at), colour: "var(--ink-mid)") if called
    end

    def ringed((x, y))
      %(<circle cx="#{x.round(2)}" cy="#{y.round(2)}" r="3.6" fill="none" ) +
        %(stroke="var(--ink)" stroke-width="1.6"/>)
    end

    # The same scale the throw's own arrow is drawn at, so the two compare.
    def carrying((x, y), across, rising)
      speed = Math.hypot(across, rising)
      return "" if speed <= 0

      long = PUSH * speed / fastest
      tip = [ (x + across / speed * long).round(2), (y - rising / speed * long).round(2) ]
      turned = Math.atan2(rising, across)
      wing = lambda do |swing|
        [ (tip[0] - Math.cos(turned + swing) * HEAD).round(2),
          (tip[1] + Math.sin(turned + swing) * HEAD).round(2) ].join(",")
      end

      %(<line x1="#{x.round(2)}" y1="#{y.round(2)}" x2="#{tip[0]}" y2="#{tip[1]}" ) +
        %(stroke="var(--ink-mid)" stroke-width="1.4"/>) +
        %(<path class="head" d="M #{tip.join(',')} L #{wing.call(0.42)} L #{wing.call(-0.42)} z" ) +
        %(fill="var(--ink-mid)"/>)
    end

    def beside_the_ring((x, y))
      [ [ x + 8, y - 6, "start" ], [ x - 8, y - 6, "end" ],
        [ x + 8, y + 16, "start" ], [ x - 8, y + 16, "end" ],
        [ x, y - 18, "middle" ], [ x, y + 26, "middle" ] ]
    end

    def note(text, when: nil)
      return unless value(binding.local_variable_get(:when))

      want(text, [ [ WIDTH / 2, 30, "middle" ] ], colour: "var(--red)")
    end

    def to_svg(settled = {})
      placing = Drawing::Placing.new(WIDTH, HEIGHT, settled)
      drawn = placing.resolve(@wanted)
      @settled = placing.settled

      %(<svg id="diagram" viewBox="0 0 #{WIDTH} #{HEIGHT}" aria-label="the picture"#{held}>) +
        @shapes.join + drawn.join + reachable + "</svg>"
    end

    attr_reader :settled

    private

    # How much ground is in view. A chapter that offers it as a control is
    # answered from there, because then it is the reader's; failing that it is
    # the chapter's, in `across`; and failing that the frame is cut for the
    # fastest throw the chapter allows under the pull it is under, which the
    # playground already said in the far end of its own control.
    #
    # What it must not be is cut to fit whatever was just thrown. That draws
    # every throw the same size, and then nothing the reader does shows.
    def fastest = @scenario.class.playground.inputs[:u][:range].end
    def pull = value(:g) || 9.81
    def span = (value(:in_view) || @across || fastest**2 / pull).to_f
    def scale = REACH / span

    def along(metres) = START + metres * scale
    def up(metres) = GROUND - metres * scale

    # y = x tan θ − g x² ⁄ 2u² cos²θ, walked from the hand to the ground.
    def arc(turned)
      speed = value(:u)
      reached = value(:r)
      return "" if speed.nil? || reached.nil? || reached.zero?

      # Nothing pushes it sideways, so it covers the ground at a steady rate:
      # walking the arc in equal steps of across is walking it in equal steps
      # of time, which is what lets the ball be paced by the physics below.
      @walked = (0..STEPS).map do |n|
        across = reached * n / STEPS
        high = across * Math.tan(turned) -
               pull * across**2 / (2 * speed**2 * Math.cos(turned)**2)
        [ along(across).round(3), up(high).round(3) ]
      end

      drawn = @walked.map { |point| point.join(",") }

      %(<path id="flight" d="M #{drawn.join(' L ')}" fill="none" stroke="var(--light)" ) +
        %(stroke-width="2.5" stroke-linecap="round"/>) + flying
    end

    # The arc is where it went; this is it going. Nothing here chooses how
    # long that takes — the law was asked, and the ball is in the air for the
    # time of flight it answered with. Pull harder and it hurries.
    #
    # Nor does anything here choose how it is paced. Left to itself the motion
    # would run at one speed along the arc, which no thrown thing does: it is
    # quickest leaving and landing and slowest at the top, where none of its
    # going is upward any more. So each vertex is told when it is reached —
    # evenly, because the vertices are even in time — and how far along the
    # arc that is, which is not even at all.
    def flying
      seconds = value(:t_f)
      return "" if seconds.nil? || seconds < 1e-6 || @walked.nil?

      steps = @walked.each_cons(2).map { |(from, to)| Math.hypot(to[0] - from[0], to[1] - from[1]) }
      arc = steps.sum
      return "" if arc < 1e-9

      gone = steps.each_with_object([ 0.0 ]) { |step, kept| kept << kept.last + step }
      reached = gone.map { |so_far| (so_far / arc).round(4) }
      clock = (0..STEPS).map { |n| (n.to_f / STEPS).round(4) }

      %(<circle class="ball" r="3.5" fill="var(--light)">) +
        %(<animateMotion dur="#{seconds.round(3)}s" repeatCount="indefinite" ) +
        %(calcMode="linear" keyTimes="#{clock.join(';')}" keyPoints="#{reached.join(';')}">) +
        %(<mpath href="#flight"/></animateMotion></circle>)
    end

    ARC = 26
    ARC_STEPS = 12

    # The angle it left at, drawn where it is made: an arc from the ground
    # round to the throw.
    def swept(turned)
      drawn = (0..ARC_STEPS).map do |n|
        at = turned * n / ARC_STEPS
        "#{(START + Math.cos(at) * ARC).round(2)},#{(GROUND - Math.sin(at) * ARC).round(2)}"
      end

      %(<polyline points="#{drawn.join(' ')}" fill="none" stroke="var(--ink-soft)" ) +
        %(stroke-width="1" opacity="0.7"/>) + reading(turned)
    end

    def reading(turned)
      shown = format("%.1f°", turned.in_degrees)
      at = turned / 2

      %(<text x="#{(START + Math.cos(at) * (ARC + 13)).round(2)}" ) +
        %(y="#{(GROUND - Math.sin(at) * (ARC + 13) + 4).round(2)}" ) +
        %(font-size="9" fill="var(--ink-soft)">#{shown}</text>)
    end

    def turf
      %(<rect x="0" y="#{GROUND}" width="#{WIDTH}" height="#{HEIGHT - GROUND}" ) +
        %(fill="var(--ink)" opacity="0.07"/>) +
        %(<line x1="0" y1="#{GROUND}" x2="#{WIDTH}" y2="#{GROUND}" ) +
        %(stroke="var(--ink-soft)" stroke-width="1.2"/>)
    end

    # The hand it left from.
    def thrown
      %(<circle cx="#{START}" cy="#{GROUND}" r="3" fill="var(--light)"/>)
    end

    FAINT = %(stroke="var(--ink-soft)" stroke-width="1").freeze
    DASHED = %(#{FAINT} stroke-dasharray="2 2").freeze

    def dropped(at)
      %(<line x1="#{at.round(2)}" y1="#{GROUND}" x2="#{at.round(2)}" y2="#{GROUND - 6}" #{FAINT}/>)
    end

    # How much ground the throw covered, laid just above the line it covered it
    # along, with an end mark at each end of it. Under the ground line is the
    # ruler's, and down there the two were reading as one thing.
    def tick(at)
      %(<line x1="#{START}" y1="#{GROUND - 6}" x2="#{at.round(2)}" y2="#{GROUND - 6}" ) +
        %(#{DASHED}/>) + [ START, at ].map { |x| capped(x, GROUND - 6, 0, 3) }.join
    end

    # And how high it got, the same measure turned upright.
    def risen(at, top)
      %(<line x1="#{at.round(2)}" y1="#{GROUND}" x2="#{at.round(2)}" y2="#{top.round(2)}" ) +
        %(#{DASHED}/>) + [ GROUND, top ].map { |y| capped(at, y, 3, 0) }.join
    end

    def capped(x, y, across, along)
      %(<line x1="#{(x - across).round(2)}" y1="#{(y - along).round(2)}" ) +
        %(x2="#{(x + across).round(2)}" y2="#{(y + along).round(2)}" #{FAINT}/>)
    end

    # Out past the top of the arc, and off to either side of it if something
    # is already standing there. A throw whose top is outside the picture is
    # named where it leaves it instead, since that is the last of it anyone
    # can see.
    def aloft(_turned)
      top = [ along(value(:r) / 2).clamp(30.0, WIDTH - 30.0),
              up(value(:h)).clamp(16.0, GROUND - 10.0) ]

      [ [ top[0], top[1] - 8, "middle" ], [ top[0] + 10, top[1] - 8, "start" ],
        [ top[0] - 10, top[1] - 8, "end" ], [ top[0], top[1] + 14, "middle" ] ]
    end

    def want(text, spots, colour: "var(--ink-soft)", fixed: false, clear: nil)
      @wanted << { text: text, spots: spots, colour: colour, fixed: fixed, clear: clear }
    end

    def draggable?(name)
      name.is_a?(Symbol) && @scenario.class.playground.inputs.key?(name)
    end

    # The angle is swung about the hand, and measured up from the ground —
    # not from an upright, the way an optics picture measures one. And the
    # hand holds two things at once: which way it is thrown is where you are
    # round from it, how hard is how far out, on the same scale the arrow is
    # drawn at.
    def held
      return "" unless @dragged

      %( data-drags="#{@dragged}" data-at="#{START} #{GROUND}") + pulled
    end

    # The arrow is the handle, so the hand runs on the arrow's scale: out to
    # where the arrow would reach is the speed that would draw it there.
    def pulled
      return "" unless @scenario.class.playground.inputs.key?(:u)

      %( data-pulls="u" data-per="#{(fastest / PUSH.to_f).round(6)}")
    end

    # Everything above the ground answers to the hand.
    def reachable
      return "" unless @dragged

      %(<rect class="grab" x="0" y="0" width="#{WIDTH}" height="#{GROUND}" fill="transparent"/>)
    end

    def value(name)
      return name if name.is_a?(Numeric)
      return @chosen[name] if @chosen.key?(name)
      return @scenario.instance_exec(&name) if name.is_a?(Proc)
      return nil if name.nil?

      if @scenario.class.conditions.key?(name)
        @scenario.satisfies?(name)
      else
        @scenario.solve(name)
      end
    rescue StandardError
      nil
    end
  end
end
