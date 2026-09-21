require "minitest/autorun"
require_relative "../../lib/light/total_internal_reflection"
require_relative "../../lib/light/reflection"

class NotationTest < Minitest::Test
  def test_a_written_name_splits_into_a_letter_and_what_trails_it
    assert_equal "<mi>i</mi>", Physics.notation(:i)
    assert_equal "<msub><mi>r</mi><mi>r</mi></msub>", Physics.notation(:rr)
    assert_equal "<msub><mi>μ</mi><mi>21</mi></msub>", Physics.notation(:mu21)
  end

  def test_a_division_becomes_a_fraction
    assert_includes Refraction.equations.fetch(:snells_law).to_mathml, "<mfrac>"
  end

  def test_a_fraction_raised_to_a_power_is_bracketed
    assert_includes Reflectance.equations.fetch(:s_polarised).to_mathml, Physics::BinOp::FENCE % "("
  end

  def test_a_fraction_on_its_own_is_not_bracketed
    refute_includes Refraction.equations.fetch(:relative_index).to_mathml, Physics::BinOp::FENCE % "("
  end

  def test_it_walks_the_tree_rather_than_the_source
    written = Refraction.equations.fetch(:snells_law)

    assert_equal "mu21 == (sin(i) / sin(rr))", written.to_s
    assert_includes written.to_mathml, "<msub><mi>μ</mi><mi>21</mi></msub>"
  end

  def test_a_title_comes_from_the_module_name
    assert_equal "Incidence", Incidence.title
    assert_equal "Total internal reflection", TotalInternalReflection.title
  end

  def test_a_law_states_its_quantities_and_where_they_came_from
    html = Refraction.to_html

    assert_includes html, "<td>angle of incidence</td>"
    assert_includes html, "<td>Incidence</td>"
    assert_includes html, "<td>relative refractive index</td>"
  end

  def test_a_law_states_its_equations_and_conditions
    html = Refraction.to_html

    assert_includes html, "<figcaption>snells law</figcaption>"
    assert_includes html, 'figure class="law condition"'
  end

  def test_a_guarded_equation_states_what_it_waits_for
    assert_includes TotalInternalReflection.to_html,
                    '<span class="when">when no refracted ray</span>'
  end

  def test_quantities_alone_state_themselves_without_any_law
    html = Incidence.to_html

    assert_includes html, "<td>angle of incidence</td>"
    refute_includes html, "<figure"
  end
end
