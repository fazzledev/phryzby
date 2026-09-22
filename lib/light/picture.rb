require_relative "../physics"
require_relative "placing"

module Light
  class Picture
    WIDTH = 300
    HEIGHT = 200
    CENTRE = [ 150, 100 ].freeze
    REACH = 76
    HEAD = 7
    FULL = 3

    def initialize(scenario, chosen = {})
      @scenario = scenario
      @chosen = chosen
      @shapes = []
      @wanted = []
    end

    def media(first, second)
      @shapes.unshift(ground(shade(value(first)), 0), ground(shade(value(second))), rule, upright)
      want(named_band(first), [ [ 294, 94, "end" ] ], fixed: true)
      want(named_band(second), [ [ 294, 114, "end" ] ], fixed: true)
      name_the_upright
    end

    def surface(called: "surface")
      @shapes.unshift(ground(0.55), rule, upright)
      want(called, [ [ 294, 114, "end" ] ], fixed: true)
      name_the_upright
    end

    HATCH = 9
    HATCH_DROP = 8
    HATCH_LEAN = 5

    # The notation a mirror is always drawn in: the reflecting face a solid
    # line, the back of it hatched. Nothing is behind a mirror, so nothing is
    # shaded in there either.
    def mirror(called: "mirror")
      @shapes.unshift(face, hatching, upright)
      want(called, [ [ 294, 124, "end" ] ], fixed: true)
      name_the_upright
    end

    def ray(called, arriving_at: nil, leaving_at: nil, crossing_at: nil,
            weight: nil, angle: false, unbent: false, unless: nil)
      return if skipped?(binding.local_variable_get(:unless))

      turned = value(arriving_at || leaving_at || crossing_at)
      return if turned.nil?

      share = weight && value(weight)
      drawn = share ? FULL * share : FULL
      return if drawn < 1e-9

      from, to = ends(turned, arriving_at, leaving_at)
      @shapes << straight_on(turned) if unbent
      @shapes << arrow(*from, *to, drawn, share ? 0.32 + 0.68 * share : 0.95)
      want(share ? "#{called} #{(share * 100).round}%" : called.to_s,
           beyond(from, to), colour: "var(--ray)")

      swept(turned, arriving_at, crossing_at) if angle
    end

    # A reference line at an angle, drawn the way the normal is: dashed, out
    # from where the rays meet. Nothing is drawn if there is no such angle.
    def mark(text, arriving_at:)
      turned = value(arriving_at)
      return if turned.nil?

      tip = [ (CENTRE[0] - Math.sin(turned) * REACH * 1.2).round(2),
              (CENTRE[1] - Math.cos(turned) * REACH * 1.2).round(2) ]
      @shapes << carried(CENTRE, tip, "var(--red)", "4 3")

      want("#{text} #{format("%.2f°", turned.in_degrees)}", beyond(tip, CENTRE), colour: "var(--red)")
    end

    # Where the ray would have carried on had it not bent. Which side of it
    # the refracted ray comes out on is the whole of what bending is.
    def straight_on(turned)
      on = [ (CENTRE[0] + Math.sin(turned) * REACH).round(2),
             (CENTRE[1] + Math.cos(turned) * REACH).round(2) ]

      carried(CENTRE, on, "var(--ray)", "3 5")
    end

    def note(text, when: nil)
      held = binding.local_variable_get(:when)
      return if held && !value(held)

      want(text, [ [ CENTRE[0], 162, "middle" ], [ CENTRE[0], 150, "middle" ],
                   [ CENTRE[0], 176, "middle" ] ], colour: "var(--red)")
    end

    attr_reader :settled

    def to_svg(settled = {})
      placing = Placing.new(WIDTH, HEIGHT, settled)
      drawn = placing.resolve(@wanted)
      @settled = placing.settled

      %(<svg id="diagram" viewBox="0 0 #{WIDTH} #{HEIGHT}" aria-label="the picture">) +
        @shapes.join + drawn.join + "</svg>"
    end

    private

    ARC = 30
    ARC_STEPS = 14

    # The angle a ray makes with the normal, drawn where it is made: an arc
    # from the normal round to the ray, on the ray's own side of it.
    def swept(turned, arriving, crossing)
      sideways = arriving ? -1 : 1
      downward = crossing ? 1 : -1

      drawn = (0..ARC_STEPS).map do |n|
        at(turned * n / ARC_STEPS, sideways, downward, ARC).map { |one| one.round(2) }.join(" ")
      end

      @shapes << %(<path d="M #{drawn.join(" L ")}" fill="none" stroke="var(--ink-soft)" ) +
                 %(stroke-width="1" stroke-opacity="0.65"/>)

      want(format("%.1f°", turned.in_degrees),
           [ 12, 22, 32 ].map { |out| told(turned / 2, sideways, downward, ARC + out) })
    end

    def at(turned, sideways, downward, radius)
      [ CENTRE[0] + sideways * Math.sin(turned) * radius,
        CENTRE[1] + downward * Math.cos(turned) * radius ]
    end

    def told(turned, sideways, downward, radius)
      x, y = at(turned, sideways, downward, radius)

      [ x, y + (downward.negative? ? 0 : 7), "middle" ]
    end

    PAST = 14
    ASIDE = 0.55

    # Fixed things name themselves once and are never pushed aside; only what
    # moves carries its label about.
    def want(text, spots, colour: "var(--ink-soft)", fixed: false)
      @wanted << { text: text, spots: spots, colour: colour, fixed: fixed }
    end

    # It can be read anywhere along the line it names, so it asks for the far
    # end first — rays leave the surface on the other side — and works back up
    # only if something is already there.
    def name_the_upright
      up = (HEIGHT - 10).step(20, -20).flat_map do |y|
        [ [ CENTRE[0] - 6, y, "end" ], [ CENTRE[0] + 6, y, "start" ] ]
      end

      want("normal", up, fixed: true)
    end

    # Out past the tip, then further out, then swung off to either side — a ray
    # would rather be labelled near itself than exactly where it points.
    def beyond(from, to)
      outer = [ from, to ].max_by { |point| away(point) }
      span = away(outer)
      return [ [ outer[0], outer[1], "middle" ] ] if span.zero?

      [ 0.0, 0.4, -0.4, 0.8, -0.8, 1.3, -1.3 ].flat_map do |swing|
        [ PAST, PAST * 2, PAST * 0.4, -PAST * 0.8 ].flat_map do |push|
          spot = settle(outer, swing, push)

          # The same point read the other way round: a label with no room to
          # its right can still grow to its left.
          [ spot, [ spot[0], spot[1], spot[2] == "end" ? "start" : "end" ] ]
        end
      end
    end

    def settle(outer, swing, push)
      span = away(outer)
      across, down = (outer[0] - CENTRE[0]) / span, (outer[1] - CENTRE[1]) / span
      across, down = turn(across, down, swing)
      across = across.negative? ? -[ across.abs, ASIDE ].max : [ across, ASIDE ].max
      length = Math.hypot(across, down)

      [ outer[0] + across / length * push,
        outer[1] + down / length * push + (down.negative? ? -2 : 9),
        across.negative? ? "end" : "start" ]
    end

    def turn(across, down, by)
      [ across * Math.cos(by) - down * Math.sin(by),
        across * Math.sin(by) + down * Math.cos(by) ]
    end

    def away(point) = Math.hypot(point[0] - CENTRE[0], point[1] - CENTRE[1])

    def value(name)
      return name if name.is_a?(Numeric)
      return @chosen[name] if @chosen.key?(name)
      return @scenario.instance_exec(&name) if name.is_a?(Proc)

      if @scenario.class.conditions.key?(name)
        @scenario.satisfies?(name)
      else
        @scenario.solve(name)
      end
    rescue StandardError
      nil
    end

    def skipped?(condition)
      return false if condition.nil?

      value(condition) ? true : false
    end

    # The symbol, and what the medium is if it is one anybody has a name for.
    def named_band(name)
      held = value(name)
      ground = @scenario.class.playground
      called = held && ground.standing_on(name, held)
      return called.to_s if ground.chosen.key?(name)

      called ? "#{symbol(name)} #{called}" : symbol(name)
    end

    def symbol(name) = Physics.symbol(@scenario.class.playground.written_for(name))

    def ends(turned, arriving, leaving)
      point = if arriving
                [ CENTRE[0] - Math.sin(turned) * REACH, CENTRE[1] - Math.cos(turned) * REACH ]
              elsif leaving
                [ CENTRE[0] + Math.sin(turned) * REACH, CENTRE[1] - Math.cos(turned) * REACH ]
              else
                [ CENTRE[0] + Math.sin(turned) * REACH, CENTRE[1] + Math.cos(turned) * REACH ]
              end

      arriving ? [ point, CENTRE ] : [ CENTRE, point ]
    end

    def arrow(x1, y1, x2, y2, width, opacity)
      span = Math.hypot(x2 - x1, y2 - y1)
      ux, uy = (x2 - x1) / span, (y2 - y1) / span
      bx, by = x2 - ux * HEAD, y2 - uy * HEAD
      half = HEAD * 0.42

      %(<line x1="#{x1}" y1="#{y1}" x2="#{bx}" y2="#{by}" stroke="var(--ray)" ) +
        %(stroke-width="#{width}" stroke-opacity="#{opacity}"/>) +
        %(<path d="M #{x2} #{y2} L #{bx - uy * half} #{by + ux * half} ) +
        %(L #{bx + uy * half} #{by - ux * half} z" fill="var(--ray)" fill-opacity="#{opacity}"/>)
    end

    def ground(opacity, top = 100)
      %(<rect x="0" y="#{top}" width="#{WIDTH}" height="#{HEIGHT / 2}" ) +
        %(fill="var(--ink-soft)" opacity="#{opacity}"/>)
    end

    # Denser reads denser. Refraction turns on the ratio of the two indices,
    # so what matters is that the halves can be told apart at a glance. Air is
    # μ = 1 and gets nothing: with nothing in the way, nothing is on the page.
    #
    # There is no densest medium, so the scale approaches its limit instead of
    # stopping at one. A straight line had to stop, and everything past where
    # it stopped was the same shade as everything else past it.
    THICKEST = 0.62
    SPREAD = 1.6

    def shade(index)
      return 0.3 unless index

      (THICKEST * (1 - Math.exp(-(index - 1) / SPREAD))).round(3)
    end

    def rule = %(<line x1="0" y1="100" x2="300" y2="100" stroke="var(--rule)" stroke-width="1"/>)

    def face
      %(<line x1="0" y1="#{CENTRE[1]}" x2="#{WIDTH}" y2="#{CENTRE[1]}" ) +
        %(stroke="var(--ink-soft)" stroke-width="2"/>)
    end

    def hatching
      HATCH_LEAN.step(WIDTH, HATCH).map do |x|
        %(<line x1="#{x}" y1="#{CENTRE[1]}" x2="#{x - HATCH_LEAN}" y2="#{CENTRE[1] + HATCH_DROP}" ) +
          %(stroke="var(--ink-soft)" stroke-width="1" stroke-opacity="0.55"/>)
      end.join
    end

    def upright = carried([ 150, 10 ], [ 150, 190 ], "var(--ink-soft)", "3 4")

    # A construction line runs through shading that can be nearly its own
    # colour, so it carries a little of the paper with it, the way the labels
    # do.
    def carried(from, to, colour, dashes)
      line = ->(stroke, width) do
        %(<line x1="#{from[0]}" y1="#{from[1]}" x2="#{to[0]}" y2="#{to[1]}" ) +
          %(stroke="#{stroke}" stroke-width="#{width}"/>)
      end

      %(<g stroke-dasharray="#{dashes}">) + line.("var(--paper)", 3) + line.(colour, 1) + %(</g>)
    end
  end
end
