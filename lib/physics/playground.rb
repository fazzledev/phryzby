module Physics
  class Playground
    HANDLE = "0.85rem".freeze
    HALF_HANDLE = "0.425rem".freeze

    UNITS = {
      degrees: ->(value) { format("%.2f°", value.in_degrees) },
      percent: ->(value) { format("%.1f%%", value * 100) },
      number:  ->(value) { format("%.4g", value) },
      metres:  ->(value) { format("%.2f m", value) },
      seconds: ->(value) { format("%.2f s", value) },
      speed:   ->(value) { format("%.1f m/s", value) },
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

    # What the chapter is for. The one before it should have left the reader
    # holding this, and the one after it is whatever this answer leaves
    # hanging in turn.
    def question(text) = @question = text

    # What the chapter is called and what it is about. It names the whole page,
    # so it belongs to none of the three things the page is made of.
    def heading
      [ "<h1>#{@title}</h1>",
        @question ? "<p class=\"asked\">#{@question}</p>" : "",
        @description ? "<p class=\"lede\">#{@description}</p>" : "" ].join
    end

    # What is stated is the scenario, not one law inside it. A page that draws
    # a reflected ray and reports its angle should not be hiding the law that
    # gives it. It goes under the files it was read from.
    def stated = @scenario.to_html

    # The engine draws nothing itself; a subject brings its own way of
    # picturing, and this only holds on to it.
    def draw(canvas, **how, &block)
      @canvas = canvas
      @drawn = how
      @picture = block
    end

    # Where the labels settled last time, so they stay put rather than hunt.
    # A caller wanting a picture that depends on nothing before it says so.
    def picture(values, settled: (@settled ||= {}))
      return "" unless @picture

      drawing = @canvas.new(posing(**values), worths(values), **@drawn)
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
    # A chapter that works nothing out says nothing under Outputs, and the
    # heading goes with it.
    def to_html(values)
      [ "<div id=\"picture\">#{picture(values)}</div>",
        head("Inputs"), controls,
        @outputs.empty? ? "" : head("Outputs"),
        "<div id=\"readouts\">#{readouts(values)}</div>" ].join
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

    # How finely a control moves is a property of what it carries, not of the
    # chapter: a tenth of a degree, a hundredth of an index.
    FINELY = { degrees: 0.1.deg, number: 0.01, speed: 0.1, metres: 0.1 }.freeze

    # One verb for everything a chapter hands the laws. A range to slide
    # through, a few named things to pick between, or, given a block, a value
    # worked out from what was picked and never shown at all.
    def input(name, offered = nil, default: nil, in: nil, as: nil, marks: {}, &worked_out)
      return @given[name] = worked_out if worked_out
      return @inputs[name] = picking(name, offered, default, as) if offered.is_a?(Hash)

      units = binding.local_variable_get(:in) || read_as(name)

      @inputs[name] = { range: offered || as_far_as(name), units: units,
                        step: FINELY.fetch(units, 0.01), default: default,
                        as: as, marks: marks }
    end

    # An angle is already held within a domain, and a slider runs the whole of
    # it. The ends are the interesting ones: square on and edge on are where a
    # law stops saying anything ordinary.
    def as_far_as(name) = @scenario.domains.fetch(@scenario.quantities[name])

    # A property you have rather than a number you set: it steps from one
    # named thing to the next and reads out the name, never the value
    # underneath it.
    def picking(name, table, default, as)
      @chosen[name] = table

      { range: 0..(table.size - 1), step: 1, as: as, units: nil, table: table,
        default: table.keys.index(default || table.keys.first),
        marks: table.keys.each_with_index.to_h }
    end

    def output(name, in: nil, as: nil, alarm: false, &worked_out)
      @outputs << { name: name, units: binding.local_variable_get(:in) || read_as(name),
                  as: as, alarm: alarm, from: worked_out }
    end

    # How a quantity reads is something the laws have already said. One held
    # to a right angle is an angle; a condition is a yes or a no. Only what no
    # law names — a worked-out block, a fraction — has to say so itself.
    def read_as(name)
      return :plain if @scenario.conditions.key?(name)
      return :degrees if @scenario.domains[@scenario.quantities[name]] == A_RIGHT_ANGLE

      :number
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
        label = entry[:as] || (entry[:from] ? entry[:name].to_s : called(entry[:name]))

        "<div#{entry[:alarm] ? ' class="alarm"' : ""}><span>#{label}</span>" \
          "<span class=\"var\">#{written(entry[:name])}</span>" \
          "<span class=\"val\">#{found}</span></div>"
      end

      "<div class=\"out\">#{rows.join}</div>"
    end

    def controls
      @inputs.map { |name, set| set[:table] ? picked(name, set) : slid(name, set) }.join
    end

    def slid(name, set)
      "<div class=\"field\">#{titles(name, set, aimed: true)}" \
        "<div class=\"track\">#{marked(name, set)}" \
        "<input type=\"range\" id=\"#{name}\" data-input=\"#{name}\" " \
        "min=\"#{set[:range].begin}\" max=\"#{set[:range].end}\" step=\"#{set[:step]}\" " \
        "value=\"#{set[:default]}\"></div>" \
        "<output id=\"#{name}-out\">#{reading(set, set[:default])}</output></div>"
    end

    # One of a few named things, with nothing in between them to slide through.
    def picked(name, set)
      buttons = set[:table].keys.each_with_index.map do |called, at|
        "<label class=\"pick\"><input type=\"radio\" name=\"#{name}\" " \
          "data-input=\"#{name}\" value=\"#{at}\"#{at == set[:default] ? " checked" : ""}>" \
          "<span>#{called}</span></label>"
      end

      "<div class=\"field\">#{titles(name, set)}" \
        "<div class=\"picks\">#{buttons.join}</div></div>"
    end

    # A control is named twice: by what the number is, and by the letter the
    # equation above writes it as. They get a column each, so a long name
    # wrapping does not push the letter about.
    def titles(name, set, aimed: false)
      "<label#{aimed ? " for=\"#{name}\"" : ""}>#{set[:as] || called(name)}</label>" \
        "<span class=\"var\">#{written(name)}</span>"
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

    def opening = @inputs.transform_values { |set| set[:default] }

    # The scenario itself, posed with these values — what the console holds on
    # to so somebody can ask it their own questions.
    def posing(**values) = @scenario.new(**posed(values))

    # What each chosen name is worth, which is the only thing about it a law
    # could use.
    def worths(values)
      @chosen.to_h { |name, table| [ name, table.values[values.fetch(name).to_i] ] }
    end

    # A chosen name stands for what it is worth, and a `given` turns what the
    # page holds — whatever was picked and whatever was slid — into something
    # a law has a quantity for.
    def posed(values)
      return values if @given.empty?

      held = values.except(*@chosen.keys).merge(worths(values))
      here = held.empty? ? Data.define.new : Data.define(*held.keys).new(**held)

      values.except(*@chosen.keys)
            .merge(@given.transform_values { |how| here.instance_exec(&how) })
    end

    private

    def called(name) = (@scenario.quantities[name] || name).to_s.tr("_", " ")

    # What the equation writes it as. A condition is not a quantity and has no
    # letter of its own.
    def written(name)
      return nil unless @scenario.quantities.key?(name)

      Physics.symbol(written_for(name))
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
