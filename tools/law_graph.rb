require "json"

# Every quantity a chapter's laws name and every equation that mentions it,
# with no direction. An equation can be turned any way round — which way it
# happens to point depends on what you gave it, not on the law — so the web
# says only what holds what together.
#
# It is a chapter's scenario rather than one law, because a chapter composes:
# what it can answer comes from all the laws it plays with at once.
module LawGraph
  WHERE = File.expand_path("../laws.json", __dir__)
  PLAYGROUNDS = Dir[File.expand_path("../lib/playground/**/*.rb", __dir__)].sort.freeze

  # lib/playground/light/water_to_air.rb is the chapter at light/water-to-air.html
  def self.page(path)
    part = path[%r{lib/playground/(.+)\.rb}, 1]

    "#{File.dirname(part)}/#{File.basename(part).tr("_", "-")}.html"
  end

  # A letter and what sits under it, kept apart so the page can set the one
  # beneath the other. Plain text can only do that for digits; SVG can do it
  # for anything, and the law already said where the subscript starts.
  def self.letter(law, quantity)
    stem, under = Physics.written_as(law.written(quantity) || quantity)

    [ Physics::LETTER.fetch(stem, stem), under ]
  end

  def self.web(law)
    { nodes: law.quantities.values.uniq.map { |q|
               base, under = letter(law, q)
               { id: "q:#{q}", kind: "quantity", base: base, under: under,
                 called: q.to_s.tr("_", " ") }
             } + (law.equations.to_a + law.conditions.to_a).map { |name, holds|
               # What it says, set the way the law pane sets it. These have no
               # names in any book — they are results, labelled by their
               # subject — so the statement is the only honest identity.
               { id: "e:#{name}", kind: law.conditions.key?(name) ? "condition" : "equation",
                 said: name.to_s.tr("_", " "), maths: holds.to_mathml }
             },
      links: (law.equations.to_a + law.conditions.to_a).flat_map { |name, holds|
               holds.variables.map { |q| { source: "e:#{name}", target: "q:#{q}" } }
             } }
  end

  # Each playground in turn, because Physics.playground answers with whichever
  # arrived last — the same reason the suite names each one as it loads it.
  # Loaded rather than required: require declines the second time and would
  # hand back whichever chapter happened to be last, for every chapter.
  def self.chapters
    PLAYGROUNDS.to_h do |path|
      load path
      ground = Physics.playground
      scenario = ground.posing(**ground.opening).class

      [ page(path), { called: ground.heading[%r{<h1>(.*?)</h1>}, 1], **web(scenario) } ]
    end
  end

  def self.to_json(*) = JSON.pretty_generate(chapters)
end

if $PROGRAM_NAME == __FILE__
  require_relative "../lib/physics"
  File.write(LawGraph::WHERE, "#{LawGraph.to_json}\n")
  puts "wrote #{LawGraph::WHERE}"
  JSON.parse(File.read(LawGraph::WHERE)).each do |page, web|
    puts format("  %-40s %-28s %2d quantities, %2d equations", page, web["called"],
                web["nodes"].count { |n| n["kind"] == "quantity" },
                web["nodes"].count { |n| n["kind"] != "quantity" })
  end
end
