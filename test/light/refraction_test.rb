require "minitest/autorun"
require_relative "../../lib/light/reflection"
require_relative "../../lib/light/refraction"

class RefractionTest < Minitest::Test
  SURFACE = Physics::Scenario[Reflection, Refraction]
  FLAT_ALONG_THE_SURFACE = Math::PI / 2

  AIR = 1.0
  WATER = 1.33
  GLASS = 1.5

  def test_air_into_glass_refracts_toward_the_normal
    assert_in_delta 19.4712, solved(:rr, from: AIR, into: GLASS, i: 30), 1e-3
  end

  def test_air_into_water
    assert_in_delta 32.1173, solved(:rr, from: AIR, into: WATER, i: 45), 1e-3
  end

  def test_solves_backwards_from_the_refracted_ray
    assert_in_delta 30.0, solved(:i, from: AIR, into: GLASS, rr: 19.4712), 1e-3
  end

  def test_identifies_the_medium_from_two_measured_angles
    assert_in_delta GLASS, identified(into: 19.4712, from_air_at: 30), 1e-4
    assert_in_delta WATER, identified(into: 32.1173, from_air_at: 45), 1e-4
  end

  def test_reflection_still_holds
    assert_in_delta 37.0, solved(:rl, from: AIR, into: GLASS, i: 37), 1e-6
  end

  def test_a_solved_ray_satisfies_the_law_it_was_solved_from
    ray = ray(from: AIR, into: GLASS, i: 30)
    ray.solve(:rr)

    assert ray.holds?(:snells_law)
  end

  def test_a_wrong_angle_does_not_satisfy_snell
    refute ray(from: AIR, into: GLASS, i: 30, rr: 25).holds?(:snells_law)
  end

  def test_shallow_angles_stay_on_the_physical_branch
    { 3 => 1.9990, 10 => 6.6478, 30 => 19.4712 }.each do |degrees, expected|
      assert_in_delta expected, solved(:rr, from: AIR, into: GLASS, i: degrees), 1e-3
    end
  end

  def test_total_internal_reflection_past_the_critical_angle
    assert traps?(from: GLASS, into: AIR, at: 50)
  end

  def test_no_total_internal_reflection_below_it
    refute traps?(from: GLASS, into: AIR, at: 30)
  end

  def test_the_critical_angle_itself_still_refracts
    assert_in_delta 41.8103, CRITICAL, 1e-3
    refute traps?(from: GLASS, into: AIR, at: CRITICAL)
  end

  def test_the_critical_angle_is_snell_with_the_refracted_ray_lying_flat
    found = SURFACE.new(mu1: GLASS, mu2: AIR, rr: FLAT_ALONG_THE_SURFACE).solve(:i)

    assert_in_delta CRITICAL, found.in_degrees, 1e-6
  end

  def test_going_into_a_denser_medium_never_traps_the_ray
    (1..89).each do |degrees|
      refute traps?(from: AIR, into: GLASS, at: degrees), "trapped at #{degrees} deg"
    end
  end

  def test_normal_incidence_is_outside_this_formulation
    assert_raises(RuntimeError) { solved(:rr, from: AIR, into: GLASS, i: 0) }
  end

  def test_refuses_to_solve_what_is_not_determined
    ray = SURFACE.new(i: 30.deg, mu1: AIR)

    assert_raises(RuntimeError) { ray.solve(:rr) }
  end

  private

  CRITICAL = Math.asin(AIR / GLASS).in_degrees

  def ray(from:, into:, **angles)
    SURFACE.new(mu1: from, mu2: into, **angles.transform_values(&:deg))
  end

  def solved(target, from:, into:, **angles)
    ray = ray(from: from, into: into, **angles)
    ray.solve(target)
    ray[target].in_degrees
  end

  def identified(into:, from_air_at:)
    SURFACE.new(i: from_air_at.deg, rr: into.deg, mu1: AIR).solve(:mu2)
  end

  def traps?(from:, into:, at:)
    ray(from: from, into: into, i: at).satisfies?(:no_refracted_ray)
  end
end
