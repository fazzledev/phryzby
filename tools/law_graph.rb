require "json"
require_relative "../lib/light/total_internal_reflection"
require_relative "../lib/light/relative_index"
require_relative "../lib/flight/projectile"

# Every quantity a law names and every equation that mentions it, with no
# direction. An equation can be turned any way round — which way it happens to
# point depends on what you gave it, not on the law — so the web says only
# what holds what together.
module LawGraph
  SHOWN = { "Projectile" => Projectile, "Refraction" => Refraction,
            "Reflectance" => Reflectance,
            "TotalInternalReflection" => TotalInternalReflection }.freeze

  # A letter and what sits under it, kept apart so the page can set the one
  # beneath the other. Plain text can only do that for digits; SVG can do it
  # for anything, and the law already said where the subscript starts.
  def self.letter(law, quantity)
    stem, under = Physics.written_as(law.written(quantity))

    [ Physics::LETTER.fetch(stem, stem), under ]
  end

  def self.web(law)
    { nodes: law.quantities.values.uniq.map { |q|
               base, under = letter(law, q)
               { id: "q:#{q}", kind: "quantity", base: base, under: under,
                 called: q.to_s.tr("_", " ") }
             } + law.equations.keys.map { |name|
               { id: "e:#{name}", kind: "equation", said: name.to_s.tr("_", " ") }
             },
      links: law.equations.flat_map { |name, equation|
               equation.variables.map { |q| { source: "e:#{name}", target: "q:#{q}" } }
             } }
  end

  def self.to_json(*) = JSON.pretty_generate(SHOWN.transform_values { |law| web(law) })

  WHERE = File.expand_path("../laws.json", __dir__)
end

if $PROGRAM_NAME == __FILE__
  File.write(LawGraph::WHERE, "#{LawGraph.to_json}\n")
  puts "wrote #{LawGraph::WHERE}"
  LawGraph::SHOWN.each do |called, law|
    puts format("  %-24s %2d quantities, %d equations", called,
                law.quantities.values.uniq.size, law.equations.size)
  end
end
