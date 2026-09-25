require "minitest/autorun"
require_relative "../../lib/light/reflection"
require_relative "../../lib/light/refraction"
require_relative "../../lib/light/reflectance"

class ReflectanceTest < Minitest::Test
  SURFACE = Physics::Scenario.including(Reflection, Refraction, Reflectance)

  AIR = 1.0
  GLASS = 1.5

  def test_glass_reflects_about_four_percent_head_on
    assert_in_delta 0.04, share(at: 1, from: AIR, into: GLASS).last, 1e-3
  end

  def test_the_two_polarisations_agree_head_on
    r_s, r_p, = share(at: 1, from: AIR, into: GLASS)

    assert_in_delta r_s, r_p, 1e-3
  end

  def test_asking_for_the_reflectance_alone_finds_everything_it_needs
    surface = SURFACE.new(i: 40.deg, mu_1: AIR, mu_2: GLASS)
    surface.solve(:r)

    assert_in_delta 25.3739, surface[:r_r].in_degrees, 1e-3
    assert_operator surface[:r_s], :>, 0
    assert_operator surface[:r_p], :>, 0
  end

  def test_p_polarised_light_vanishes_at_brewsters_angle
    _, r_p, = share(at: BREWSTER, from: AIR, into: GLASS)

    assert_in_delta 0.0, r_p, 1e-6
    assert_in_delta 56.31, BREWSTER, 1e-2
  end

  def test_s_polarised_light_does_not_vanish_there
    r_s, = share(at: BREWSTER, from: AIR, into: GLASS)

    assert_operator r_s, :>, 0.1
  end

  def test_everything_reflects_at_the_critical_angle
    critical = Math.asin(AIR / GLASS).in_degrees
    _, _, r = share(at: critical, from: GLASS, into: AIR)

    assert_in_delta 1.0, r, 1e-4
  end

  def test_reflection_grows_as_the_angle_opens
    shares = [ 10, 30, 50, 70, 85 ].map { |a| share(at: a, from: AIR, into: GLASS).last }

    assert_equal shares.sort, shares
  end

  def test_grazing_incidence_reflects_nearly_everything
    assert_operator share(at: 89, from: AIR, into: GLASS).last, :>, 0.7
  end

  def test_s_polarised_always_reflects_at_least_as_much
    (1..89).each do |degrees|
      r_s, r_p, = share(at: degrees, from: AIR, into: GLASS)

      assert_operator r_s, :>=, r_p - 1e-9, "failed at #{degrees} deg"
    end
  end

  def test_unpolarised_is_the_mean_of_the_two
    r_s, r_p, r = share(at: 40, from: AIR, into: GLASS)

    assert_in_delta (r_s + r_p) / 2, r, 1e-9
  end

  def test_the_two_shares_account_for_all_of_the_light
    reflected = SURFACE.new(i: 40.deg, mu_1: AIR, mu_2: GLASS).solve(:r)

    assert_in_delta 1.0, reflected + (1.0 - reflected), 1e-12
  end

  private

  BREWSTER = Math.atan(GLASS / AIR).in_degrees

  def share(at:, from:, into:)
    surface = SURFACE.new(i: at.deg, mu_1: from, mu_2: into)

    [ surface.solve(:r_s), surface.solve(:r_p), surface.solve(:r) ]
  end
end
