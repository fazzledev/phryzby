require "minitest/autorun"
require_relative "../../lib/light/incidence"

class IncidenceTest < Minitest::Test
  SURFACE = Physics::Scenario[Incidence]

  def test_it_states_a_quantity_and_is_not_a_law
    assert_equal({ angle_of_incidence: :angle_of_incidence, i: :angle_of_incidence },
                 Incidence.quantities)

    refute_respond_to Incidence, :equations
    refute_respond_to Incidence, :equation
  end

  def test_a_value_given_can_be_read_back
    assert_in_delta 30.0, SURFACE.new(i: 30.deg)[:i].in_degrees, 1e-9
  end

  def test_the_alias_and_the_full_name_are_the_same_variable
    ray = SURFACE.new(angle_of_incidence: 30.deg)

    assert_in_delta 30.0, ray[:i].in_degrees, 1e-9
  end

  def test_declaring_a_quantity_does_not_determine_it
    error = assert_raises(RuntimeError) { SURFACE.new.solve(:i) }

    assert_match(/no equation determines angle_of_incidence/, error.message)
  end

  def test_the_declared_branch_travels_with_the_quantity
    assert_equal Physics::A_RIGHT_ANGLE, Incidence.domains.fetch(:angle_of_incidence)
  end

  def test_a_law_that_includes_it_says_the_same_thing
    require_relative "../../lib/light/reflection"

    assert_equal :angle_of_incidence, Reflection.quantities.fetch(:i)
    assert_equal Physics::A_RIGHT_ANGLE, Reflection.domains.fetch(:angle_of_incidence)
  end
end
