module Physics
  class Showing
    UNITS = {
      degrees: ->(value) { format("%.2f°", value.in_degrees) },
      percent: ->(value) { format("%.1f%%", value * 100) },
      number:  ->(value) { format("%.4g", value) },
      plain:   ->(value) { value ? "yes" : "no" },
    }.freeze

    def initialize(scenario)
      @scenario = scenario
      @inputs = {}
      @outputs = []
      @picture = nil
    end

    attr_reader :inputs, :outputs, :picture

    def title(text) = @title = text
    def description(text) = @description = text

    # What is stated is the scenario, not one law inside it. A page that draws
    # a reflected ray and reports its angle should not be hiding the law that
    # gives it.
    def stated
      [ "<h1>#{@title}</h1>",
        @description ? "<p class=\"lede\">#{@description}</p>" : "",
        @scenario.to_html ].join
    end

    # The engine draws nothing itself; a subject brings its own way of
    # picturing, and this only holds on to it.
    def draws(canvas, &block)
      @canvas = canvas
      @picture = block
    end

    def picture(values)
      return "" unless @picture

      drawing = @canvas.new(@scenario.new(**values))
      drawing.instance_eval(&@picture)
      drawing.to_svg
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
        controls,
        "<div id=\"readouts\">#{readouts(values)}</div>" ].join
    end

    # What changes when a control moves: the picture, the numbers, and the
    # reading beside each control.
    def moved(values)
      labels = @inputs.map { |name, set| "#{name}\u0001#{UNITS.fetch(set[:units]).call(values[name])}" }

      [ picture(values), readouts(values), labels.join("\u0002") ].join("\u0000")
    end

    def input(name, range, step:, at:, in: :number, as: nil)
      @inputs[name] = { range: range, step: step, at: at, as: as,
                        units: binding.local_variable_get(:in) }
    end

    def output(name, in: :number, as: nil, alarm: false, &worked_out)
      @outputs << { name: name, units: binding.local_variable_get(:in),
                  as: as, alarm: alarm, from: worked_out }
    end

    def draw(&block) = @picture = block

    def read(scenario, name)
      return scenario.satisfies?(name) if @scenario.conditions.key?(name)

      scenario.solve(name)
    end

    def readouts(values)
      scenario = @scenario.new(**values)

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
          "<input type=\"range\" id=\"#{name}\" data-input=\"#{name}\" min=\"#{set[:range].begin}\" " \
          "max=\"#{set[:range].end}\" step=\"#{set[:step]}\" value=\"#{set[:at]}\">" \
          "<output id=\"#{name}-out\">#{UNITS.fetch(set[:units]).call(set[:at])}</output></div>"
      end.join
    end

    def opening = @inputs.transform_values { |set| set[:at] }

    private

    def named(name)
      (@scenario.quantities[name] || name).to_s.tr("_", " ")
    end
  end

  # A page loads one shown file and shows what it declared.
  def self.shown = @outputs
  def self.shows(scenario) = @outputs = scenario

  class Scenario
    def self.showing(&block)
      showing_of.instance_eval(&block)
      Physics.shows(self)
      self
    end

    def self.showing_of = @showing ||= Showing.new(self)
  end
end
