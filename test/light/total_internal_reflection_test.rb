require "minitest/autorun"
require_relative "../../lib/light/reflection"
require_relative "../../lib/light/total_internal_reflection"

class TotalInternalReflectionTest < Minitest::Test
  SURFACE = Physics::Scenario[Reflection, TotalInternalReflection]

  AIR = 1.0
  GLASS = 1.5
  CRITICAL = Math.asin(AIR / GLASS).in_degrees

  def test_past_the_critical_angle_everything_reflects
    assert_in_delta 1.0, share(at: 50), 1e-12
    assert_in_delta 1.0, share(at: 70), 1e-12
    assert_in_delta 1.0, share(at: 89), 1e-12
  end

  def test_below_it_fresnel_still_decides
    assert_operator share(at: 30), :<, 0.1
    assert_in_delta 0.0552, share(at: 30), 1e-3
  end

  def test_the_guarded_law_is_invisible_until_its_condition_holds
    refute surface(at: CRITICAL).satisfies?(:no_refracted_ray)

    assert_operator share(at: CRITICAL), :<, 1.0
    assert_in_delta 0.99999, share(at: CRITICAL), 1e-5
  end

  def test_fresnel_climbs_to_one_on_its_own_and_the_guarded_law_pins_it_there
    assert_in_delta 0.9799, share(at: CRITICAL - 0.0003), 1e-3
    assert_operator share(at: CRITICAL), :<, 1.0
    assert_in_delta 1.0, share(at: CRITICAL + 0.01), 1e-12
  end

  def test_a_denser_second_medium_never_traps_the_ray
    (1..89).each do |degrees|
      refute SURFACE.new(i: degrees.deg, mu1: AIR, mu2: GLASS)
                    .satisfies?(:no_refracted_ray), "trapped at #{degrees} deg"
    end
  end

  def test_the_law_is_stated_here_and_the_condition_comes_from_refraction
    assert_equal :no_refracted_ray, TotalInternalReflection.guards.fetch(:everything_reflects)
    assert_equal %i[everything_reflects], TotalInternalReflection.equations.keys - Reflectance.equations.keys
  end

  private

  def surface(at:) = SURFACE.new(i: at.deg, mu1: GLASS, mu2: AIR)
  def share(at:) = surface(at: at).solve(:r)
end
