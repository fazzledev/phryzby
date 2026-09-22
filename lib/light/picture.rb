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

    def initialize(scenario)
      @scenario = scenario
      @shapes = []
      @wanted = []
    end

    def media(first, second)
      @shapes.unshift(ground(0.3), rule, upright)
      want(symbol(first), [ [ 294, 94, "end" ] ])
      want(symbol(second), [ [ 294, 114, "end" ] ])
      name_the_upright
    end

    def surface(called: "surface")
      @shapes.unshift(ground(0.55), rule, upright)
      want(called, [ [ 294, 114, "end" ] ])
      name_the_upright
    end

    def ray(called, arriving_at: nil, leaving_at: nil, crossing_at: nil, weight: nil, unless: nil)
      return if skipped?(binding.local_variable_get(:unless))

      angle = arriving_at || leaving_at || crossing_at
      turned = value(angle)
      return if turned.nil?

      share = weight && value(weight)
      drawn = share ? FULL * share : FULL
      return if drawn < 1e-9

      from, to = ends(turned, arriving_at, leaving_at)
      @shapes << arrow(*from, *to, drawn, share ? 0.32 + 0.68 * share : 0.95)
      want(share ? "#{called} #{(share * 100).round}%" : called.to_s,
           beyond(from, to), colour: "var(--ray)")
    end

    # A reference line at an angle, drawn the way the normal is: faint, dashed,
    # out from where the rays meet. Nothing is drawn if there is no such angle.
    def mark(text, arriving_at:)
      turned = value(arriving_at)
      return if turned.nil?

      tip = [ CENTRE[0] - Math.sin(turned) * REACH * 1.2, CENTRE[1] - Math.cos(turned) * REACH * 1.2 ]
      @shapes << %(<line x1="#{CENTRE[0]}" y1="#{CENTRE[1]}" x2="#{tip[0].round(2)}" ) +
                 %(y2="#{tip[1].round(2)}" stroke="var(--red)" stroke-width="1" ) +
                 %(stroke-opacity="0.55" stroke-dasharray="4 3"/>)

      want("#{text} #{format("%.2f°", turned.in_degrees)}", beyond(tip, CENTRE), colour: "var(--red)")
    end

    def note(text, when: nil)
      held = binding.local_variable_get(:when)
      return if held && !value(held)

      want(text, [ [ CENTRE[0], 162, "middle" ], [ CENTRE[0], 150, "middle" ],
                   [ CENTRE[0], 176, "middle" ] ], colour: "var(--red)")
    end

    def to_svg
      drawn = Placing.new(WIDTH, HEIGHT).resolve(@wanted)

      %(<svg id="diagram" viewBox="0 0 #{WIDTH} #{HEIGHT}" aria-label="the picture">) +
        @shapes.join + drawn.join + "</svg>"
    end

    private

    PAST = 14
    ASIDE = 0.55

    def want(text, spots, colour: "var(--ink-soft)", last: false)
      @wanted << { text: text, spots: spots, colour: colour, last: last }
    end

    # The dashed line has a whole height to be named anywhere along, so it asks
    # last and takes what is left.
    def name_the_upright
      want("normal", (15..185).step(11).flat_map { |y| [ [ 156, y, "start" ], [ 144, y, "end" ] ] },
           last: true)
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

    UNDER = { "0" => "₀", "1" => "₁", "2" => "₂", "3" => "₃", "4" => "₄",
              "5" => "₅", "6" => "₆", "7" => "₇", "8" => "₈", "9" => "₉" }.freeze

    # mu1 is a mu with a one under it, the same reading the typeset law uses.
    def symbol(name)
      written = @scenario.class.showing_of.written_for(name).to_s
      stem = Physics::GREEK.find { |greek| written.start_with?(greek) }
      letter = stem ? Physics::LETTER.fetch(stem) : written[0]
      trail = written[(stem ? stem.length : 1)..].to_s

      letter + trail.chars.map { |mark| UNDER.fetch(mark, mark) }.join
    end

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

    def ground(opacity)
      %(<rect x="0" y="100" width="300" height="100" fill="var(--rule)" opacity="#{opacity}"/>)
    end

    def rule = %(<line x1="0" y1="100" x2="300" y2="100" stroke="var(--rule)" stroke-width="1"/>)

    def upright
      %(<line x1="150" y1="10" x2="150" y2="190" stroke="var(--rule)" stroke-width="1" ) +
        %(stroke-dasharray="3 4"/>)
    end
  end
end
