require "json"

# Every quantity a chapter's laws name and every equation that mentions it,
# with no direction. An equation can be turned any way round — which way it
# happens to point depends on what you gave it, not on the law — so the web
# says only what holds what together.
#
# It is a chapter's scenario rather than one law, because a chapter composes:
# what it can answer comes from all the laws it plays with at once.
module LawWeb
  WHERE = File.expand_path("../web.json", __dir__)
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

  # A chapter is a question: these quantities are handed over, and those are
  # the ones being asked for. The playground has already said which is which —
  # what it offers a control for is given, and what it prints a reading of is
  # wanted — so the web only has to name them the way its own nodes are named.
  def self.asked(ground, law)
    { solving: taken(ground, law),
      given: (ground.inputs.keys + ground.given.keys).filter_map { |name| node(law, name) }.uniq,
      wanted: ground.outputs.reject { |out| out[:from] }
                    .filter_map { |out| node(law, out[:name]) }.uniq }
  end

  # The way the solver actually goes. It tries whichever equation has the
  # fewest unknowns left and stops at the first answer, so of the four ways to
  # the range it takes one and never sees the others. The rest of the web is
  # the alternates, and they are every bit as true — this is only the road it
  # happened to drive down.
  def self.taken(ground, law)
    scenario = ground.posing(**ground.opening)

    ground.outputs.reject { |out| out[:from] }.each do |out|
      if law.conditions.key?(out[:name]) then scenario.satisfies?(out[:name])
      else scenario.solve(out[:name])
      end
    rescue StandardError
      nil
    end

    scenario.worked.flat_map { |key, names| names.map { |name| "e:#{name}" } << "q:#{key}" }.uniq
  end

  # A name as the web knows it. A quantity goes by what it stands for, since
  # a chapter may ask for it under any of its spellings; a condition is a
  # statement and stands for itself; and what a reading works out in Ruby the
  # laws never named at all.
  def self.node(law, name)
    return "e:#{name}" if law.conditions.key?(name)

    stands_for = law.quantities[name]
    stands_for && "q:#{stands_for}"
  end

  def self.web(law)
    { nodes: law.quantities.values.uniq.map { |q|
               base, under = letter(law, q)
               { id: "q:#{q}", kind: "quantity", base: base, under: under,
                 called: q.to_s.tr("_", " ") }
             } + law.identities.map { |name, said|
               { id: "e:#{name}", kind: "identity", said: name.to_s.tr("_", " "),
                 maths: said[:holds].to_mathml }
             } + (law.equations.to_a + law.conditions.to_a).map { |name, holds|
               # What it says, set the way the law pane sets it. These have no
               # names in any book — they are results, labelled by their
               # subject — so the statement is the only honest identity.
               { id: "e:#{name}", kind: law.conditions.key?(name) ? "condition" : "equation",
                 said: name.to_s.tr("_", " "), maths: holds.to_mathml }
             },
      links: (law.equations.to_a + law.conditions.to_a).flat_map { |name, holds|
               holds.variables.map { |q| { source: "e:#{name}", target: "q:#{q}" } }
             } +
             # An identity touches statements rather than quantities: it is
             # what stands between two that say the same thing.
             law.identities.flat_map { |name, said|
               said[:reconciles].select { |one| law.equations.key?(one) }
                                .map { |one| { source: "e:#{name}", target: "e:#{one}" } }
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

      [ page(path), { called: ground.heading[%r{<h1>(.*?)</h1>}, 1],
                      **asked(ground, scenario), **web(scenario) } ]
    end
  end

  def self.to_json(*) = JSON.pretty_generate(chapters)
end

if $PROGRAM_NAME == __FILE__
  require_relative "../lib/physics"
  File.write(LawWeb::WHERE, "#{LawWeb.to_json}\n")
  puts "wrote #{LawWeb::WHERE}"
  JSON.parse(File.read(LawWeb::WHERE)).each do |page, web|
    puts format("  %-40s %-28s %2d quantities, %2d equations", page, web["called"],
                web["nodes"].count { |n| n["kind"] == "quantity" },
                web["nodes"].count { |n| n["kind"] != "quantity" })
  end
end
