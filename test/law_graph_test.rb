require "minitest/autorun"
require_relative "../tools/law_graph"

# The web the page draws is generated from the laws, so it can fall behind
# them. This is the thing that notices: a law that gains a quantity and a file
# that does not is a failing test rather than a picture quietly telling the
# reader something that stopped being true.
class LawGraphTest < Minitest::Test
  def test_the_file_the_page_reads_says_what_the_laws_say
    assert_equal "#{LawGraph.to_json}\n", File.read(LawGraph::WHERE),
                 "laws.json is behind the laws — run: ruby tools/law_graph.rb"
  end

  def test_every_equation_reaches_every_quantity_it_mentions
    web = LawGraph.web(Projectile)
    named = web[:nodes].map { |node| node[:id] }

    Projectile.equations.each do |name, equation|
      equation.variables.each do |quantity|
        assert_includes web[:links], { source: "e:#{name}", target: "q:#{quantity}" }
      end
    end
    assert_empty web[:links].flat_map { |link| link.values_at(:source, :target) } - named
  end

  # The letter and its subscript travel apart, so the page can set one under
  # the other rather than printing the underscore.
  def test_a_subscript_is_handed_over_as_a_subscript
    assert_equal [ "v", "x" ], LawGraph.letter(Projectile, :velocity_across)
    assert_equal [ "θ", "0" ], LawGraph.letter(Projectile, :angle_of_throw)
    assert_equal [ "R", nil ], LawGraph.letter(Projectile, :range)
    assert_equal [ "μ", "21" ], LawGraph.letter(RelativeIndex, :relative_refractive_index)
  end
end
