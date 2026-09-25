module Physics
  GREEK = %w[alpha beta gamma delta theta lambda mu nu pi rho sigma phi omega].freeze
  LETTER = { "alpha" => "α", "beta" => "β", "gamma" => "γ", "delta" => "δ", "theta" => "θ",
             "lambda" => "λ", "mu" => "μ", "nu" => "ν", "pi" => "π", "rho" => "ρ",
             "sigma" => "σ", "phi" => "φ", "omega" => "ω" }.freeze

  # A written name says where its subscript starts, and only an underscore
  # says so: mu_21 is a mu with 21 under it and v_x a v with an x, while i is
  # just an i. Nothing is guessed from the spelling — a name that wants no
  # subscript has only to leave the underscore out.
  def self.written_as(written) = written.to_s.split("_", 2)

  def self.notation(written)
    stem, under = written_as(written)
    base = LETTER.fetch(stem, stem)

    under ? "<msub><mi>#{base}</mi><mi>#{under}</mi></msub>" : "<mi>#{base}</mi>"
  end

  UNDER = { "0" => "₀", "1" => "₁", "2" => "₂", "3" => "₃", "4" => "₄",
            "5" => "₅", "6" => "₆", "7" => "₇", "8" => "₈", "9" => "₉" }.freeze

  # The same, in plain text rather than MathML, for the places a page has no
  # room for a formula. Plain text can only set a subscript where there is a
  # character for one — digits have them, letters do not — so a subscript it
  # cannot set it leaves written the way the law wrote it.
  def self.symbol(written)
    stem, under = written_as(written)
    base = LETTER.fetch(stem, stem)
    return base unless under

    base + (under.chars.all? { |mark| UNDER.key?(mark) } ? under.chars.map { |mark| UNDER.fetch(mark) }.join
                                                         : "_#{under}")
  end

  PRECEDENCE = { :+ => 1, :- => 1, :* => 2, :/ => 3, :** => 4 }.freeze

  class Expr
    def to_mathml(_under = nil) = "<mi>?</mi>"
    def precedence = 9
  end

  class Const
    def to_mathml(_under = nil) = "<mn>#{@value}</mn>"
  end

  class Var
    def to_mathml(_under = nil) = Physics.notation(@written)
  end

  class Fn
    # &#x2061; is function application, which is invisible and takes no room,
    # so the thin space a typesetter would leave has to be asked for.
    def to_mathml(_under = nil)
      "<mi>#{@name}</mi><mo>&#x2061;</mo><mspace width=\"0.17em\"/>#{@arg.to_mathml(:**)}"
    end
  end

  class BinOp
    # Browsers only stretch a bracket when a maths font is installed to stretch
    # it with, so the size is asked for rather than hoped for.
    FENCE = "<mo class=\"fence\" stretchy=\"false\">%s</mo>".freeze

    def precedence = PRECEDENCE.fetch(@op, 9)

    def to_mathml(under = nil)
      body =
        case @op
        when :/  then "<mfrac>#{row(@left)}#{row(@right)}</mfrac>"
        when :** then "<msup>#{row(@left, :**)}#{row(@right)}</msup>"
        when :*  then "#{@left.to_mathml(@op)}<mo>&#x22c5;</mo>#{@right.to_mathml(@op)}"
        else "#{@left.to_mathml(@op)}<mo>#{@op}</mo>#{@right.to_mathml(@op)}"
        end

      bracketed?(under) ? "#{FENCE % "("}#{body}#{FENCE % ")"}" : body
    end

    private

    # A fraction draws its own grouping, except under a power, where the
    # exponent would otherwise look as though it sat on the numerator.
    def bracketed?(under)
      return false unless under
      return false if @op == :/ && under != :**

      PRECEDENCE.fetch(under, 9) > precedence
    end

    def row(part, under = nil) = "<mrow>#{part.to_mathml(under)}</mrow>"
  end

  class Equation
    def to_mathml = "#{@left.to_mathml}<mo>=</mo>#{@right.to_mathml}"
  end

  class Comparison
    SIGN = { :> => "&gt;", :< => "&lt;", :>= => "&#x2265;", :<= => "&#x2264;" }.freeze

    def to_mathml = "#{@left.to_mathml}<mo>#{SIGN.fetch(@op, @op)}</mo>#{@right.to_mathml}"
  end
end

module Physics
  module Quantities
    def title = name.to_s.gsub(/([a-z])([A-Z])/) { "#{$1} #{$2.downcase}" }

    def borrowed = included_modules.select { |part| part.respond_to?(:quantities) }

    def source(key) = borrowed.find { |part| part.quantities.value?(key) }

    def written(key) = quantities.find { |name, means| means == key && name != key }&.first

    # A law states what it is made of. How it is introduced to a reader is
    # somebody else's business.
    def to_html = quantity_rows

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
    def to_html = super + laws + holding

    private

    # The same declarations a third way. The table says what the quantities
    # are and the formulas say what each equation asserts; neither says which
    # equations reach which quantities, and that is what decides whether a
    # question can be answered at all. A mark where one holds the other.
    def holding
      held = quantities.values.uniq
      return "" if held.size < 2 || equations.size < 2

      rows = equations.map { |name, holds| touching(name, holds, held, "equation") } +
             conditions.map { |name, holds| touching(name, holds, held, "condition") }

      "<table class=\"holds\"><thead><tr><th></th>" \
        "#{held.map { |key| "<th>#{set(written(key) || key)}</th>" }.join}" \
        "</tr></thead><tbody>#{rows.join}</tbody></table>"
    end

    def set(written) = "<math><mrow>#{Physics.notation(written)}</mrow></math>"

    def touching(name, holds, held, kind)
      mentioned = holds.variables

      "<tr class=\"#{kind}\"><th scope=\"row\">#{name.to_s.tr("_", " ")}</th>" \
        "#{held.map { |key| "<td#{mentioned.include?(key) ? " class=\"on\"" : ""}></td>" }.join}" \
        "</tr>"
    end

    def laws
      (equations.map { |name, holds| rule(name, holds.to_mathml, guards[name]) } +
       conditions.map { |name, holds| rule(name, holds.to_mathml, nil, "condition") }).join
    end

    def rule(name, mathml, guard, kind = "equation")
      caveat = guard ? "<span class=\"when\">when #{guard.to_s.tr("_", " ")}</span>" : ""

      "<figure class=\"law #{kind}\">" \
        "<math display=\"block\"><mrow>#{mathml}</mrow></math>" \
        "<figcaption>#{name.to_s.tr("_", " ")}#{caveat}</figcaption></figure>"
    end
  end
end
