module Physics
  class Playground
    HANDLE = "0.85rem".freeze
    HALF_HANDLE = "0.425rem".freeze

    UNITS = {
      degrees: ->(value) { format("%.2f°", value.in_degrees) },
      percent: ->(value) { format("%.1f%%", value * 100) },
      number:  ->(value) { format("%.4g", value) },
      plain:   ->(value) { value ? "yes" : "no" },
    }.freeze

    def initialize(scenario)
      @scenario = scenario
      @inputs = {}
      @chosen = {}
      @given = {}
      @outputs = []
      @picture = nil
    end

    attr_reader :inputs, :chosen, :outputs, :picture

    def title(text) = @title = text
    def description(text) = @description = text

    # What the chapter is called and what it is about. It names the whole page,
    # so it belongs to none of the three things the page is made of.
    def heading
      [ "<h1>#{@title}</h1>",
        @description ? "<p class=\"lede\">#{@description}</p>" : "" ].join
    end

    # What is stated is the scenario, not one law inside it. A page that draws
    # a reflected ray and reports its angle should not be hiding the law that
    # gives it. It goes under the files it was read from.
    def stated = @scenario.to_html

    # The engine draws nothing itself; a subject brings its own way of
    # picturing, and this only holds on to it.
    def draw(canvas, &block)
      @canvas = canvas
      @picture = block
    end

    # Where the labels settled last time, so they stay put rather than hunt.
    # A caller wanting a picture that depends on nothing before it says so.
    def picture(values, settled: (@settled ||= {}))
      return "" unless @picture

      drawing = @canvas.new(posing(**values), worths(values))
      drawing.instance_eval(&@picture)
      drawn = drawing.to_svg(settled)
      @settled = drawing.settled

      drawn
    end

    # The variable a quantity is written as, not the quantity's own name.
    def written_for(name)
      means = @scenario.quantities[name] || name
      @scenario.quantities.find { |written, stands_for| stands_for == means && written != means }
               &.first || means
    end

    # The playground, and nothing else. Where it sits on the page is the
    # page's business, and what the law says is the law's.
    def to_html(values)
      [ "<div id=\"picture\">#{picture(values)}</div>",
        head("Inputs"), controls,
        head("Outputs"), "<div id=\"readouts\">#{readouts(values)}</div>" ].join
    end

    # Each heading names the verb that made what is under it, so the page and
    # the playground file beside it can be read straight across.
    def head(text) = "<div class=\"head\">#{text}</div>"

    # What changes when a control moves: the picture, the numbers, and the
    # reading beside each control.
    def moved(values)
      labels = @inputs.map { |name, set| "#{name}\u0001#{reading(set, values[name])}" }

      [ picture(values), readouts(values), labels.join("\u0002") ].join("\u0000")
    end

    def input(name, range, step:, at:, in: :number, as: nil, marks: {})
      @inputs[name] = { range: range, step: step, at: at, as: as, marks: marks,
                        units: binding.local_variable_get(:in) }
    end

    # A property you have rather than a number you set: the slider steps from
    # one named thing to the next and reads out the name, never the value
    # underneath it.
    def choose(name, table, at:, as: nil)
      @chosen[name] = table
      @inputs[name] = { range: 0..(table.size - 1), step: 1, at: table.keys.index(at),
                        as: as, units: nil, table: table,
                        marks: table.keys.each_with_index.to_h }
    end

    # What the laws are actually given, worked out from what was chosen. The
    # chosen names are in scope, standing for what they are worth.
    def given(name, &how) = @given[name] = how

    def output(name, in: :number, as: nil, alarm: false, &worked_out)
      @outputs << { name: name, units: binding.local_variable_get(:in),
                  as: as, alarm: alarm, from: worked_out }
    end

    def read(scenario, name)
      return scenario.satisfies?(name) if @scenario.conditions.key?(name)

      scenario.solve(name)
    end

    def readouts(values)
      scenario = posing(**values)

      rows = @outputs.map do |entry|
        found = begin
          if entry[:from]
            answer = scenario.instance_exec(&entry[:from])
            answer.is_a?(Numeric) ? UNITS.fetch(entry[:units]).call(answer) : answer.to_s
          else
            UNITS.fetch(entry[:units]).call(read(scenario, entry[:name]))
          end
        rescue StandardError
          "—"
        end
        label = entry[:as] || (entry[:from] ? entry[:name].to_s : named(entry[:name]))

        "<div#{entry[:alarm] ? ' class="alarm"' : ""}><span>#{label}</span>" \
          "<span class=\"val\">#{found}</span></div>"
      end

      "<div class=\"out\">#{rows.join}</div>"
    end

    def controls
      @inputs.map do |name, set|
        "<div class=\"field\"><label for=\"#{name}\">#{set[:as] || named(name)}</label>" \
          "<div class=\"track\">#{marked(name, set)}" \
          "<input type=\"range\" id=\"#{name}\" data-input=\"#{name}\" " \
          "min=\"#{set[:range].begin}\" max=\"#{set[:range].end}\" step=\"#{set[:step]}\" " \
          "value=\"#{set[:at]}\"></div>" \
          "<output id=\"#{name}-out\">#{reading(set, set[:at])}</output></div>"
      end.join
    end

    # Notches along the track, at the values somebody would recognise. Each is
    # worth aiming at, so each is worth pressing.
    def marked(name, set)
      return "" if set[:marks].empty?

      span = set[:range].end - set[:range].begin
      notches = set[:marks].map do |called, value|
        # A slider's handle travels inset by its own width, not edge to edge,
        # so a notch has to be laid along the same shorter run.
        along = ((value - set[:range].begin) / span).round(4)

        "<button type=\"button\" class=\"mark\" data-set=\"#{value}\" data-for=\"#{name}\" " \
          "style=\"left:calc(#{HALF_HANDLE} + (100% - #{HANDLE}) * #{along})\" " \
          "title=\"#{called}\"><span>#{called}</span></button>"
      end

      "<div class=\"marks\">#{notches.join}</div>"
    end

    # What a value is standing on, if it is standing on anything.
    def standing_on(name, value)
      set = @inputs[name]
      return nil unless set && value
      return set[:table].key(value) if set[:table]

      set[:marks].find { |_, at| (at - value).abs < set[:step] / 2 + 1e-9 }&.first
    end

    def reading(set, value)
      return set[:table].keys[value.to_i].to_s if set[:table]

      shown = UNITS.fetch(set[:units]).call(value)
      near = set[:marks].find { |_, mark| (mark - value).abs < set[:step] / 2 + 1e-9 }

      near ? "#{shown}<small>#{near.first}</small>" : shown
    end

    def opening = @inputs.transform_values { |set| set[:at] }

    # The scenario itself, posed with these values — what the console holds on
    # to so somebody can ask it their own questions.
    def posing(**values) = @scenario.new(**posed(values))

    # What each chosen name is worth, which is the only thing about it a law
    # could use.
    def worths(values)
      @chosen.to_h { |name, table| [ name, table.values[values.fetch(name).to_i] ] }
    end

    # A chosen name stands for what it is worth, and a `given` turns what was
    # chosen into something a law has a quantity for.
    def posed(values)
      return values if @chosen.empty?

      here = Data.define(*@chosen.keys).new(**worths(values))

      values.except(*@chosen.keys)
            .merge(@given.transform_values { |how| here.instance_exec(&how) })
    end

    private

    def named(name)
      (@scenario.quantities[name] || name).to_s.tr("_", " ")
    end
  end

  # A page loads one playground file and plays with what it declared.
  def self.playground = @playground
  def self.plays(playground) = @playground = playground

  module Sideways
    # The same surface asked a different question: everything it knows except
    # the thing being asked for, plus whatever is given instead.
    def asking(target, **knowns)
      key = self.class.quantities.fetch(target)
      posed = as_posed.reject { |held, _| held == key }

      self.class.new(**posed, **knowns).solve(target)
    end
  end

  class Scenario
    def self.played_with(&block)
      playground.instance_eval(&block)
      Physics.plays(playground)
      self
    end

    def self.playground = @playground ||= Playground.new(self)
  end
end

Physics::Scenario.include(Physics::Sideways)

# A playground file opens by naming the laws it is about and nothing else.
def play_with(*laws, &how) = Physics::Scenario.including(*laws).played_with(&how)
