require_relative "../physics"
require_relative "../drawing/placing"
require_relative "refractive_media"

module Light
  class Picture
    WIDTH = 300
    HEIGHT = 200
    CENTRE = [ 150, 100 ].freeze
    REACH = 76
    HEAD = 7
    FULL = 3

    def initialize(scenario, chosen = {}, rising: false)
      @scenario = scenario
      @chosen = chosen
      @rising = rising
      @shapes = []
      @wanted = []
    end

    # Light crossing downwards is the ordinary way to draw it, and the wrong
    # way round when the first medium is water: a pond is under the air, not
    # over it. A rising chapter puts its first medium at the bottom and sends
    # the ray up out of it, and everything that knows which way is into the
    # first medium asks here.
    def into_first = @rising ? 1 : -1
    def first_half = @rising ? 100 : 0
    def second_half = @rising ? 0 : 100
    def band_y(half) = half.zero? ? 94 : 114

    def media(first, second)
      @within = value(first)
      @shapes.unshift(ground(shade(value(first)), first_half),
                      ground(shade(value(second)), second_half), rule, upright)
      want(named_band(first), [ [ 294, band_y(first_half), "end" ] ], fixed: true)
      want(named_band(second), [ [ 294, band_y(second_half), "end" ] ], fixed: true)
      name_the_upright
    end

    def surface(called: "surface", across: nil)
      @shapes.unshift(*banded(across && value(across)), rule, upright)
      want(called, [ [ 294, band_y(second_half), "end" ] ], fixed: true)
      name_the_upright
    end

    # Told nothing, a surface is just a surface and the far side of it is
    # something. Told the ratio, it shades whichever side the ratio says is
    # the denser, by as much as it says: 1.33 of the other one looks the way
    # water looks against air, because it is the same number.
    def banded(turn)
      return [ ground(0.55, second_half) ] if turn.nil?
      return [] if (turn - 1).abs < 1e-9

      turn > 1 ? [ ground(shade(turn), second_half) ] : [ ground(shade(1 / turn), first_half) ]
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
            weight: nil, angle: false, extended: false, unless: nil)
      return if skipped?(binding.local_variable_get(:unless))

      turned = value(arriving_at || leaving_at || crossing_at)
      return if turned.nil?

      share = weight && value(weight)
      drawn = share ? FULL * share : FULL
      return if drawn < 1e-9

      @dragged ||= arriving_at if draggable?(arriving_at)

      from, to = ends(turned, arriving_at, leaving_at)
      @shapes << extending(turned) if extended

      # A ray that arrives comes out of something, so it starts where that
      # thing ends rather than running through the middle of it.
      @shapes << arrow(*(arriving_at ? stepped(from, to, AWAY) : from), *to,
                       drawn, share ? 0.32 + 0.68 * share : 0.95)
      @shapes << source(from) if arriving_at
      # A ray never has its own name written across its own source, and the
      # spots it asks for are otherwise the same as any other ray's, so two
      # rays pointing alike are still thrown aside alike.
      want(share ? "#{called} #{(share * 100).round}%" : called.to_s,
           beyond(from, to), colour: "var(--light)", clear: arriving_at && @standing)

      swept(turned, arriving_at, crossing_at) if angle
    end

    # A reference line at an angle, drawn the way the normal is: dashed, out
    # from where the rays meet. Nothing is drawn if there is no such angle.
    def mark(text, arriving_at:)
      turned = value(arriving_at)
      return if turned.nil?

      tip = [ (CENTRE[0] - Math.sin(turned) * REACH * 1.2).round(2),
              (CENTRE[1] + into_first * Math.cos(turned) * REACH * 1.2).round(2) ]
      @shapes << carried(CENTRE, tip, "var(--red)", "4 3")

      # It runs out on the arriving side, the same side the ray comes in on,
      # so it keeps off what is standing there as the ray does.
      want("#{text} #{format("%.2f°", turned.in_degrees)}",
           alongside(tip, CENTRE) + beyond(tip, CENTRE),
           colour: "var(--red)", clear: @standing)
    end

    # A line can be read anywhere along itself, and the far end of one is
    # where the light comes from and where a steep mark has nothing but a
    # corner. So it starts near the surface and works outward, either side.
    def alongside(from, to)
      (0..7).flat_map do |n|
        part = 0.22 + n * 0.1
        x = to[0] + (from[0] - to[0]) * part
        y = to[1] + (from[1] - to[1]) * part

        [ [ (x - 5).round(2), (y + 4).round(2), "end" ],
          [ (x + 5).round(2), (y + 4).round(2), "start" ] ]
      end
    end

    # The ray carried on past the boundary, where it would have gone had it
    # not bent. Which side of it the refracted ray comes out on is the whole
    # of what bending is.
    def extending(turned)
      on = [ (CENTRE[0] + Math.sin(turned) * REACH).round(2),
             (CENTRE[1] - into_first * Math.cos(turned) * REACH).round(2) ]

      carried(CENTRE, on, "var(--light)", "3 5")
    end

    def note(text, when: nil)
      held = binding.local_variable_get(:when)
      return if held && !value(held)

      lines = @rising ? [ 38, 50, 24 ] : [ 162, 150, 176 ]

      want(text, lines.map { |y| [ CENTRE[0], y, "middle" ] }, colour: "var(--red)")
    end

    attr_reader :settled

    def to_svg(settled = {})
      placing = Drawing::Placing.new(WIDTH, HEIGHT, settled)
      drawn = placing.resolve(@wanted)
      @settled = placing.settled

      %(<svg id="diagram" viewBox="0 0 #{WIDTH} #{HEIGHT}" aria-label="the picture"#{held}>) +
        @shapes.join + drawn.join + reachable + "</svg>"
    end

    private

    # A ray whose angle a control sets can be taken hold of and swung, and the
    # control follows. One the chapter holds cannot: there is nothing for the
    # dragging to move.
    def draggable?(name)
      name.is_a?(Symbol) && @scenario.class.playground.inputs.key?(name)
    end

    def held
      return "" unless @dragged

      %( data-drags="#{@dragged}" data-into="#{into_first}")
    end

    # The quarter the incident ray lives in, and the only part of the picture
    # worth taking hold of. Laid over the rest so the hand is told where the
    # ray is before it presses, rather than after.
    def reachable
      return "" unless @dragged

      %(<rect class="grab" x="0" y="#{first_half}" width="#{CENTRE[0]}" ) +
        %(height="#{HEIGHT / 2}" fill="transparent"/>)
    end

    ARC = 30
    ARC_STEPS = 14
    ASTRIDE = 28

    # The angle a ray makes with the normal, drawn where it is made: an arc
    # from the normal round to the ray, on the ray's own side of it.
    def swept(turned, arriving, crossing)
      sideways = arriving ? -1 : 1
      downward = crossing ? -into_first : into_first

      drawn = (0..ARC_STEPS).map do |n|
        at(turned * n / ARC_STEPS, sideways, downward, ARC).map { |one| one.round(2) }.join(" ")
      end

      @shapes << %(<path d="M #{drawn.join(" L ")}" fill="none" stroke="var(--ink-soft)" ) +
                 %(stroke-width="1" stroke-opacity="0.65"/>)

      # Out along the bisector first, and further out after that; and if the
      # whole of that line is spoken for, which it is when a narrow angle
      # crowds everything into one place, off to either side of it.
      want(format("%.1f°", turned.in_degrees),
           [ 12, 22, 32, 44 ].flat_map do |out|
             x, y, = told(turned / 2, sideways, downward, ARC + out)

             [ [ x, y, "middle" ], [ x + ASTRIDE, y, "middle" ], [ x - ASTRIDE, y, "middle" ] ]
           end)
    end

    def at(turned, sideways, downward, radius)
      [ CENTRE[0] + sideways * Math.sin(turned) * radius,
        CENTRE[1] + downward * Math.cos(turned) * radius ]
    end

    def told(turned, sideways, downward, radius)
      x, y = at(turned, sideways, downward, radius)

      [ x, y + (downward.negative? ? 0 : 7), "middle" ]
    end

    WATER = REFRACTIVE_MEDIA.fetch("water")
    AWAY = 12

    def stepped(from, to, by)
      span = Math.hypot(to[0] - from[0], to[1] - from[1])

      [ from[0] + ((to[0] - from[0]) / span * by).round(2),
        from[1] + ((to[1] - from[1]) / span * by).round(2) ]
    end

    SUN = 4
    SPOKES = 8
    SPOKE_IN = 6
    SPOKE_OUT = 9

    # A ray comes from somewhere. At the tail of the one that arrives, which
    # is also the end a reader can take hold of, so the picture says where the
    # light starts and where the hand goes in the same mark.
    #
    # The sun where the sun could be, which is over the surface and not under
    # it. A chapter that rises starts its ray inside the first medium, and
    # what can be there depends on what it is: a fish if the medium is water,
    # and inside a solid a flaw, which is the only thing that lives in glass.
    def source(at)
      return sun(at) unless @rising
      return flaw(at) unless wet?

      standing(at, [ -15, -10, 12, 10 ])
      %(<g transform="translate(#{at[0].round(2)} #{at[1].round(2)})" ) +
        %(fill="var(--light)">#{FISH}</g>)
    end

    def wet? = @within && (@within - WATER).abs < 1e-9

    # Inside a solid there is nothing alive to be the source, but there is
    # always a flaw, and catching the light is how a flaw comes to be seen at
    # all.
    def flaw(at)
      standing(at, [ -6, -6, 6, 6 ])
      %(<g transform="translate(#{at[0].round(2)} #{at[1].round(2)})" fill="var(--light)">) +
        %(<path d="M -5.5 -1.5 L -1.5 -6 L 3.5 -4.5 L 6 0.5 L 2 5.5 L -3.5 3.5 z"/></g>)
    end

    def sun(at)
      standing(at, [ -SPOKE_OUT, -SPOKE_OUT, SPOKE_OUT, SPOKE_OUT ])
      spokes = (0...SPOKES).map do |n|
        turned = n * 2 * Math::PI / SPOKES
        across, down = Math.cos(turned), Math.sin(turned)

        %(<line x1="#{(at[0] + across * SPOKE_IN).round(2)}" ) +
          %(y1="#{(at[1] + down * SPOKE_IN).round(2)}" ) +
          %(x2="#{(at[0] + across * SPOKE_OUT).round(2)}" ) +
          %(y2="#{(at[1] + down * SPOKE_OUT).round(2)}" stroke="var(--light)" stroke-width="1.2"/>)
      end

      %(<circle cx="#{at[0].round(2)}" cy="#{at[1].round(2)}" r="#{SUN}" fill="var(--light)"/>) +
        spokes.join
    end

    # A curve rises half as far as the point that pulls it, so the body needs
    # asking for twice what it should come to. The fins stand where the body
    # actually is at that point along it, rather than beside it.
    FISH = %(<path d="M -8 0 Q 2 -10 12 0 Q 2 10 -8 0 z"/>) +
           %(<path d="M -7 0 L -14 -4 L -14 4 z"/>) +
           %(<path d="M -1 -4.6 L 1 -10 L 6 -4.2 z"/>) +
           %(<path d="M -1 4.6 L 0 8.6 L 4 4.8 z"/>) +
           %(<circle cx="7" cy="-1.8" r="1" fill="var(--paper)"/>)

    # Where the last source drawn stands, for the ray coming out of it to
    # keep its name off.
    def standing(at, (left, top, right, bottom))
      @standing = [ at[0] + left, at[1] + top, at[0] + right, at[1] + bottom ]
    end

    PAST = 14
    ASIDE = 0.55

    # Fixed things name themselves once and are never pushed aside; only what
    # moves carries its label about.
    def want(text, spots, colour: "var(--ink-soft)", fixed: false, clear: nil)
      @wanted << { text: text, spots: spots, colour: colour, fixed: fixed, clear: clear }
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
      return REFRACTIVE_MEDIA.fetch(name) if name.is_a?(String)
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
    # A chapter that holds its two media says which they are, and that is the
    # whole of the name.
    def named_band(name)
      return name if name.is_a?(String)

      held = value(name)
      ground = @scenario.class.playground
      called = held && ground.standing_on(name, held)
      return called.to_s if ground.chosen.key?(name)

      called ? "#{symbol(name)} #{called}" : symbol(name)
    end

    def symbol(name) = Physics.symbol(@scenario.class.playground.written_for(name))

    def ends(turned, arriving, leaving)
      across = Math.sin(turned) * REACH
      along = into_first * Math.cos(turned) * REACH

      point = if arriving
                [ CENTRE[0] - across, CENTRE[1] + along ]
              elsif leaving
                [ CENTRE[0] + across, CENTRE[1] + along ]
              else
                [ CENTRE[0] + across, CENTRE[1] - along ]
              end

      arriving ? [ point, CENTRE ] : [ CENTRE, point ]
    end

    def arrow(x1, y1, x2, y2, width, opacity)
      span = Math.hypot(x2 - x1, y2 - y1)
      ux, uy = (x2 - x1) / span, (y2 - y1) / span
      bx, by = x2 - ux * HEAD, y2 - uy * HEAD
      half = HEAD * 0.42

      %(<line x1="#{x1}" y1="#{y1}" x2="#{bx}" y2="#{by}" stroke="var(--light)" ) +
        %(stroke-width="#{width}" stroke-opacity="#{opacity}"/>) +
        %(<path class="head" d="M #{x2} #{y2} L #{bx - uy * half} #{by + ux * half} ) +
        %(L #{bx + uy * half} #{by - ux * half} z" fill="var(--light)" fill-opacity="#{opacity}"/>)
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
