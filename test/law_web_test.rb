require "minitest/autorun"
require_relative "../lib/physics"
require_relative "../tools/law_web"
require_relative "../lib/light/relative_index"
require_relative "../lib/flight/motion"

# The web the page draws is generated from the laws, so it can fall behind
# them. This is the thing that notices: a law that gains a quantity and a file
# that does not is a failing test rather than a picture quietly telling the
# reader something that stopped being true.
class LawWebTest < Minitest::Test
  def test_the_file_the_page_reads_says_what_the_laws_say
    assert_equal "#{LawWeb.to_json}\n", File.read(LawWeb::WHERE),
                 "web.json is behind the laws — run: ruby tools/law_web.rb"
  end

  # Every chapter has one, and every edge in it reaches a node that is in it.
  def test_every_chapter_has_a_web_that_joins_up
    webs = LawWeb.chapters

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
    webs = LawWeb.chapters
    pills = ->(page) { webs.fetch(page)[:nodes].count { |node| node[:kind] != "quantity" } }

    assert_equal 9, pills.call("flight/projectile.html")
    assert_equal 15, pills.call("flight/motion.html")
    assert_operator pills.call("light/total-internal-reflection.html"), :>,
                    pills.call("light/reflectance.html")
  end

  # A chapter is a question, and the playground already asked it: its controls
  # are what is handed over and its readings are what it asks for. Both ends have
  # to be named the way the nodes are, or the page marks nothing.
  def test_a_chapter_says_what_is_given_and_what_is_asked_for
    webs = LawWeb.chapters

    assert_equal %w[q:angle_of_throw q:speed q:gravity], webs["flight/projectile.html"][:given]
    assert_equal %w[q:range q:peak q:time_of_flight], webs["flight/projectile.html"][:asked]

    webs.each do |page, web|
      named = web[:nodes].map { |node| node[:id] }

      assert_empty web[:given] - named, "#{page} is given something the web has no node for"
      assert_empty web[:asked] - named, "#{page} asks for something the web has no node for"
    end
  end

  # The solver takes one way of the several the web offers, and the chapter
  # shows which. Of the four ways to the range it drives down one; the rest
  # are the roads not taken and stay on the map.
  def test_a_chapter_says_which_way_the_solver_went
    took = LawWeb.chapters["flight/projectile.html"][:solving]

    assert_includes took, { from: "e:range_written_out", to: "q:range" }
    assert_includes took, { from: "q:speed", to: "e:range_written_out" }
    assert_includes took, { from: "e:initial_velocity_up", to: "q:initial_velocity_up" }

    through = took.flat_map { |step| step.values_at(:from, :to) }

    refute_includes through, "e:horizontal_range"
    refute_includes through, "e:range_by_the_double_angle"
  end

  # The web has no direction and a solution does: an equation is turned round
  # for one thing, and everything else in it was known before it was.
  def test_a_step_points_the_way_it_was_worked
    took = LawWeb.chapters["flight/projectile.html"][:solving]
    into = ->(node) { took.select { |step| step[:to] == node }.map { |step| step[:from] } }

    assert_equal %w[e:maximum_height], into.call("q:peak")
    assert_equal %w[q:initial_velocity_up q:gravity], into.call("e:maximum_height")
  end

  # A way the solver went is a way the web has, or the page would light a road
  # that is not on the map.
  def test_the_way_taken_is_part_of_the_web
    LawWeb.chapters.each do |page, web|
      named = web[:nodes].map { |node| node[:id] }

      through = web[:solving].flat_map { |step| step.values_at(:from, :to) }.uniq

      assert_empty through - named, "#{page} solves through something not in its web"
    end
  end

  # What a chapter works out in Ruby rather than asking a law for is not a
  # node and cannot be asked for, and neither is a property picked by name.
  def test_what_no_law_names_is_neither_given_nor_asked_for
    web = LawWeb.chapters["flight/projectile.html"]

    refute_includes web[:given], "q:in_view"
    refute_includes web[:given], "q:world"
  end

  # The letter and its subscript travel apart, so the page can set one under
  # the other rather than printing the underscore.
  def test_a_subscript_is_handed_over_as_a_subscript
    assert_equal [ "v", "x" ], LawWeb.letter(Motion, :velocity_across)
    assert_equal [ "θ", "0" ], LawWeb.letter(Projectile, :angle_of_throw)
    assert_equal [ "R", nil ], LawWeb.letter(Projectile, :range)
    assert_equal [ "μ", "21" ], LawWeb.letter(RelativeIndex, :relative_refractive_index)
  end
end
