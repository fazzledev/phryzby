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
    def to_html = super + laws

    private

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
