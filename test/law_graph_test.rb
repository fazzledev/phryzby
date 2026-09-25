require "minitest/autorun"
require_relative "../lib/physics"
require_relative "../tools/law_graph"
require_relative "../lib/light/relative_index"
require_relative "../lib/flight/motion"

# The web the page draws is generated from the laws, so it can fall behind
# them. This is the thing that notices: a law that gains a quantity and a file
# that does not is a failing test rather than a picture quietly telling the
# reader something that stopped being true.
class LawGraphTest < Minitest::Test
  def test_the_file_the_page_reads_says_what_the_laws_say
    assert_equal "#{LawGraph.to_json}\n", File.read(LawGraph::WHERE),
                 "laws.json is behind the laws — run: ruby tools/law_graph.rb"
  end

  # Every chapter has one, and every edge in it reaches a node that is in it.
  def test_every_chapter_has_a_web_that_joins_up
    webs = LawGraph.chapters

    assert_equal 14, webs.size
    webs.each do |page, web|
      named = web[:nodes].map { |node| node[:id] }

      assert_empty web[:links].flat_map { |link| link.values_at(:source, :target) } - named,
                   "#{page} has an edge reaching nothing"
      assert_path_exists page
    end
  end

  # A chapter composes, so its web is of everything it plays with at once —
  # the throw's nine equations, and reflectance reaching back through Snell.
  def test_a_chapter_s_web_is_all_the_laws_it_plays_with
    webs = LawGraph.chapters
    pills = ->(page) { webs.fetch(page)[:nodes].count { |node| node[:kind] != "quantity" } }

    assert_equal 5, pills.call("flight/projectile.html")
    assert_equal 11, pills.call("flight/motion.html")
    assert_operator pills.call("light/total-internal-reflection.html"), :>,
                    pills.call("light/reflectance.html")
  end

  # The letter and its subscript travel apart, so the page can set one under
  # the other rather than printing the underscore.
  def test_a_subscript_is_handed_over_as_a_subscript
    assert_equal [ "v", "x" ], LawGraph.letter(Motion, :velocity_across)
    assert_equal [ "θ", "0" ], LawGraph.letter(Projectile, :angle_of_throw)
    assert_equal [ "R", nil ], LawGraph.letter(Projectile, :range)
    assert_equal [ "μ", "21" ], LawGraph.letter(RelativeIndex, :relative_refractive_index)
  end
end
