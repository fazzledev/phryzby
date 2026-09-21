require_relative "../physics"

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
      @parts = []
      @below = nil
    end

    def media(first, second)
      @below = [ first, second ]
      @parts.unshift(ground(0.3), rule, normal,
                     label(294, 94, symbol(first), anchor: "end"),
                     label(294, 114, symbol(second), anchor: "end"))
    end

    def surface(called: "surface")
      @parts.unshift(ground(0.55), rule, normal, label(294, 114, called, anchor: "end"))
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
      @parts << arrow(*from, *to, drawn, share ? 0.32 + 0.68 * share : 0.95)
      @parts << label(to[0] + (arriving_at ? 0 : 4), to[1] + (crossing_at ? 12 : -6),
                      share ? "#{called} #{(share * 100).round}%" : called.to_s,
                      colour: "var(--ray)", anchor: arriving_at ? "middle" : "middle")
    end

    def note(text, when: nil)
      held = binding.local_variable_get(:when)
      return if held && !value(held)

      @parts << label(CENTRE[0], 162, text, colour: "var(--red)")
    end

    def to_svg
      %(<svg id="diagram" viewBox="0 0 #{WIDTH} #{HEIGHT}" aria-label="the picture">#{@parts.join}</svg>)
    end

    private

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

    def normal
      %(<line x1="150" y1="10" x2="150" y2="190" stroke="var(--rule)" stroke-width="1" ) +
        %(stroke-dasharray="3 4"/>) + label(156, 15, "normal", anchor: "start")
    end

    def label(x, y, text, colour: "var(--ink-soft)", anchor: "middle")
      %(<text x="#{x}" y="#{y}" fill="#{colour}" text-anchor="#{anchor}" ) +
        %(font-family="ui-monospace, monospace" font-size="11">#{text}</text>)
    end
  end
end
