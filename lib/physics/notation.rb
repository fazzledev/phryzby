module Physics
  GREEK = %w[alpha beta gamma delta theta lambda mu nu pi rho sigma phi omega].freeze
  LETTER = { "alpha" => "α", "beta" => "β", "gamma" => "γ", "delta" => "δ", "theta" => "θ",
             "lambda" => "λ", "mu" => "μ", "nu" => "ν", "pi" => "π", "rho" => "ρ",
             "sigma" => "σ", "phi" => "φ", "omega" => "ω" }.freeze

  # A written name splits into a letter and what trails it: mu21 is a mu with
  # 21 under it, rr an r with an r under it, i just an i.
  def self.notation(written)
    text = written.to_s
    stem = GREEK.find { |greek| text.start_with?(greek) } || text[0]
    base = LETTER.fetch(stem, stem)
    trail = text[stem.length..]

    trail.empty? ? "<mi>#{base}</mi>" : "<msub><mi>#{base}</mi><mi>#{trail}</mi></msub>"
  end

  PRECEDENCE = { :+ => 1, :- => 1, :* => 2, :/ => 3, :** => 4 }.freeze

  # Every drawn part says where it lives in the tree, so a click on it can be
  # turned back into a change to the law.
  def self.handle(at, kind) = %( data-at="#{at}" data-kind="#{kind}")

  class Expr
    def to_mathml(_under = nil, _at = "") = "<mi>?</mi>"
    def precedence = 9
    def substitute(path, replacement) = path.empty? ? replacement : self
  end

  class Const
    def to_mathml(_under = nil, at = "") = "<mn#{Physics.handle(at, "number")}>#{@value}</mn>"
  end

  class Var
    def to_mathml(_under = nil, at = "")
      "<mrow#{Physics.handle(at, "quantity")}>#{Physics.notation(@written)}</mrow>"
    end
  end

  class Fn
    # &#x2061; is function application, which is invisible and takes no room,
    # so the thin space a typesetter would leave has to be asked for.
    def to_mathml(_under = nil, at = "")
      "<mi#{Physics.handle("#{at}n", "function")}>#{@name}</mi>" \
        "<mo>&#x2061;</mo><mspace width=\"0.17em\"/>#{@arg.to_mathml(:**, "#{at}a")}"
    end

    def substitute(path, replacement)
      return replacement if path.empty?
      return Fn.new(replacement, @arg) if path == "n"
      return Fn.new(@name, @arg.substitute(path[1..], replacement)) if path[0] == "a"

      self
    end
  end

  class BinOp
    # Browsers only stretch a bracket when a maths font is installed to stretch
    # it with, so the size is asked for rather than hoped for.
    FENCE = "<mo class=\"fence\" stretchy=\"false\">%s</mo>".freeze

    def precedence = PRECEDENCE.fetch(@op, 9)

    def to_mathml(under = nil, at = "")
      left, right = "#{at}l", "#{at}r"
      sign = "<mo#{Physics.handle("#{at}o", "operator")}>%s</mo>"

      body =
        case @op
        when :/  then "<mfrac#{Physics.handle("#{at}o", "operator")}>" \
                      "#{row(@left, nil, left)}#{row(@right, nil, right)}</mfrac>"
        when :** then "<msup#{Physics.handle("#{at}o", "operator")}>" \
                      "#{row(@left, :**, left)}#{row(@right, nil, right)}</msup>"
        when :*  then "#{@left.to_mathml(@op, left)}#{sign % "&#x22c5;"}#{@right.to_mathml(@op, right)}"
        else "#{@left.to_mathml(@op, left)}#{sign % @op}#{@right.to_mathml(@op, right)}"
        end

      bracketed?(under) ? "#{FENCE % "("}#{body}#{FENCE % ")"}" : body
    end

    def substitute(path, replacement)
      return replacement if path.empty?
      return BinOp.new(replacement, @left, @right) if path == "o"
      return BinOp.new(@op, @left.substitute(path[1..], replacement), @right) if path[0] == "l"
      return BinOp.new(@op, @left, @right.substitute(path[1..], replacement)) if path[0] == "r"

      self
    end

    private

    # A fraction draws its own grouping, except under a power, where the
    # exponent would otherwise look as though it sat on the numerator.
    def bracketed?(under)
      return false unless under
      return false if @op == :/ && under != :**

      PRECEDENCE.fetch(under, 9) > precedence
    end

    def row(part, under = nil, at = "") = "<mrow>#{part.to_mathml(under, at)}</mrow>"
  end

  module Sides
    def to_mathml = "#{@left.to_mathml(nil, "l")}<mo>#{sign}</mo>#{@right.to_mathml(nil, "r")}"

    def substitute(path, replacement)
      return self.class.new(*rebuilt(path, replacement)) if %w[l r].include?(path[0])

      self
    end
  end

  class Equation
    include Sides

    def sign = "="
    def rebuilt(path, replacement)
      path[0] == "l" ? [ @left.substitute(path[1..], replacement), @right ]
                     : [ @left, @right.substitute(path[1..], replacement) ]
    end
  end

  class Comparison
    include Sides

    SIGN = { :> => "&gt;", :< => "&lt;", :>= => "&#x2265;", :<= => "&#x2264;" }.freeze

    def sign = SIGN.fetch(@op, @op)
    def rebuilt(path, replacement)
      parts = path[0] == "l" ? [ @left.substitute(path[1..], replacement), @right ]
                             : [ @left, @right.substitute(path[1..], replacement) ]

      [ @op, *parts ]
    end
  end
end

module Physics
  module Quantities
    def title = name.to_s.gsub(/([a-z])([A-Z])/) { "#{$1} #{$2.downcase}" }

    def borrowed = included_modules.select { |part| part.respond_to?(:quantities) }

    def source(key) = borrowed.find { |part| part.quantities.value?(key) }

    def written(key) = quantities.find { |name, means| means == key && name != key }&.first

    def to_html = "<h2>#{title} <small>— as the module states it</small></h2>#{quantity_rows}"

    private

    def quantity_rows
      rows = quantities.values.uniq.map do |key|
        from = source(key)

        "<tr><td>#{key.to_s.tr("_", " ")}</td>" \
          "<td><math><mrow>#{Physics.notation(written(key) || key)}</mrow></math></td>" \
          "<td>#{domains.key?(key) ? branch(domains[key]) : "—"}</td>" \
          "<td>#{from&.name}</td></tr>"
      end

      "<table class=\"declared\"><thead><tr><th>quantity</th><th>written</th>" \
        "<th>within</th><th>from</th></tr></thead><tbody>#{rows.join}</tbody></table>"
    end

    def branch(range) = "#{format("%.4g", range.begin)} … #{format("%.4g", range.end)}"
  end

  module Declarations
    def to_html = super + laws

    private

    def laws
      (equations.map { |name, holds| rule(name, holds.to_mathml, guards[name]) } +
       conditions.map { |name, holds| rule(name, holds.to_mathml, nil, "condition") }).join
    end

    def rule(name, mathml, guard, kind = "equation")
      caveat = guard ? "<span class=\"when\">when #{guard.to_s.tr("_", " ")}</span>" : ""

      "<figure class=\"law #{kind}\" data-name=\"#{name}\">" \
        "<math display=\"block\"><mrow>#{mathml}</mrow></math>" \
        "<figcaption>#{name.to_s.tr("_", " ")}#{caveat}</figcaption></figure>"
    end
  end
end

module Physics
  APART = "\u0001".freeze
  BETWEEN = "\u0002".freeze

  module Declarations
    # Absorbing copies a law downward, so the one that wrote it is the
    # furthest away that still has it.
    def declares(name)
      stated = borrowed.select { |part| part.respond_to?(:equations) }
      stated.reverse.find { |part| part.equations.key?(name) || part.conditions.key?(name) } || self
    end
  end

  def self.leaf(law, kind, value)
    case kind
    when "number"   then Const.new(value.include?(".") ? value.to_f : value.to_i)
    when "quantity" then Var.new(law.quantities.fetch(value.to_sym), value.to_sym)
    else value.to_sym
    end
  end

  # What a click turns into: the file that has to change, and what the law
  # says once it has.
  def self.restate(law, name, at, kind, value)
    holder = law.declares(name)
    stated = holder.equations[name] || holder.conditions[name]

    [ holder.name, stated.substitute(at, leaf(law, kind, value)).to_s ].join(APART)
  end

  def self.offered(law)
    quantities = law.quantities.values.uniq
                    .map { |key| [ key.to_s.tr("_", " "), law.written(key) || key ].join(APART) }

    [ quantities.join(BETWEEN), Scope::FUNCTIONS.join(BETWEEN) ].join("\u0000")
  end
end
