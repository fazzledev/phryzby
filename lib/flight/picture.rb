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

    def initialize(scenario, chosen = {}, **_how)
      @scenario = scenario
      @chosen = chosen
      @shapes = []
      @wanted = []
    end

    # The ground it is thrown from and lands back on. Everything else is
    # measured off this line.
    def ground(called: "ground")
      @shapes.unshift(turf)
      want(called, [ [ 294, GROUND + 15, "end" ] ], fixed: true)
    end

    # The whole throw: the arc it flies, the angle it left at, and the hand
    # it left from. A throw whose angle a control sets can be swung by hand.
    def flight(called, leaving_at:)
      turned = value(leaving_at)
      return if turned.nil?

      @dragged = leaving_at if draggable?(leaving_at)
      @shapes.push(arc(turned), swept(turned), thrown)
      want(called, aloft(turned), colour: "var(--light)")
    end

    # How far it got, marked on the ground it got there along.
    def span(called, name)
      metres = value(name)
      return if metres.nil?

      @shapes.push(dropped(along(metres)), tick(along(metres)))
      want(called, [ [ along(metres), GROUND + 15, "middle" ],
                     [ along(metres) - 8, GROUND + 15, "end" ],
                     [ along(metres) + 8, GROUND + 15, "start" ] ])
    end

    # The top of the arc, marked across to the edge it is measured from.
    def apex(called, name)
      metres = value(name)
      return if metres.nil?

      @shapes.push(levelled(up(metres)))
      want(called, [ [ START - 4, up(metres) - 4, "start" ],
                     [ START - 4, up(metres) + 12, "start" ] ])
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

    # The frame is cut for the fastest throw the chapter allows, and that is
    # something the playground already said: it is the far end of the control.
    def fastest = @scenario.class.playground.inputs[:u][:range].end
    def pull = value(:g) || 9.81
    def scale = REACH / (fastest**2 / pull)

    def along(metres) = START + metres * scale
    def up(metres) = GROUND - metres * scale

    # y = x tan θ − g x² ⁄ 2u² cos²θ, walked from the hand to the ground.
    def arc(turned)
      speed = value(:u)
      reached = value(:x)
      return "" if speed.nil? || reached.nil? || reached.zero?

      points = (0..STEPS).map do |n|
        across = reached * n / STEPS
        high = across * Math.tan(turned) -
               pull * across**2 / (2 * speed**2 * Math.cos(turned)**2)
        "#{along(across).round(2)},#{up(high).round(2)}"
      end

      %(<path id="flight" d="M #{points.join(' L ')}" fill="none" stroke="var(--light)" ) +
        %(stroke-width="2.5" stroke-linecap="round"/>) + landing(turned) + flying
    end

    # The arc is where it went; this is it going. Nothing here chooses how
    # long that takes — the law was asked, and the ball is in the air for the
    # time of flight it answered with. Pull harder and it hurries.
    def flying
      seconds = value(:t)
      return "" if seconds.nil? || seconds < 1e-6

      %(<circle class="ball" r="3.5" fill="var(--light)">) +
        %(<animateMotion dur="#{seconds.round(3)}s" repeatCount="indefinite">) +
        %(<mpath href="#flight"/></animateMotion></circle>)
    end

    # The arrowhead, laid along the way it is going as it comes down — which
    # is the angle it left at, mirrored.
    def landing(turned)
      tip = [ along(value(:x)), GROUND ]
      wing = ->(swing) do
        angle = Math::PI + turned + swing
        [ (tip[0] + Math.cos(angle) * HEAD).round(2),
          (tip[1] - Math.sin(angle) * HEAD).round(2) ].join(",")
      end

      %(<path class="head" d="M #{tip.join(',')} L #{wing.call(0.42)} L #{wing.call(-0.42)} z" ) +
        %(fill="var(--light)"/>)
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

    def dropped(at)
      %(<line x1="#{at.round(2)}" y1="#{GROUND}" x2="#{at.round(2)}" y2="#{GROUND - 6}" ) +
        %(stroke="var(--ink-soft)" stroke-width="1"/>)
    end

    def tick(at)
      %(<line x1="#{START}" y1="#{GROUND + 6}" x2="#{at.round(2)}" y2="#{GROUND + 6}" ) +
        %(stroke="var(--ink-soft)" stroke-width="1" stroke-dasharray="2 2"/>)
    end

    def levelled(at)
      %(<line x1="#{START}" y1="#{at.round(2)}" x2="#{WIDTH - 10}" y2="#{at.round(2)}" ) +
        %(stroke="var(--ink-soft)" stroke-width="1" stroke-dasharray="2 2" opacity="0.7"/>)
    end

    # Out past the top of the arc, and off to either side of it if something
    # is already standing there.
    def aloft(turned)
      top = [ along(value(:x) / 2), up(value(:h)) ]

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
    # not from an upright, the way an optics picture measures one.
    def held
      return "" unless @dragged

      %( data-drags="#{@dragged}" data-at="#{START} #{GROUND}")
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
