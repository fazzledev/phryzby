require "minitest/autorun"
require_relative "../../lib/light/reflectance"

class ReflectanceTest < Minitest::Test
  AIR = 1.0
  GLASS = 1.5

  def test_glass_reflects_about_four_percent_head_on
    assert_in_delta 0.04, share(at: 1, from: AIR, into: GLASS).last, 1e-3
  end

  def test_the_two_polarisations_agree_head_on
    rs, rp, = share(at: 1, from: AIR, into: GLASS)

    assert_in_delta rs, rp, 1e-3
  end

  def test_p_polarised_light_vanishes_at_brewsters_angle
    _, rp, = share(at: BREWSTER, from: AIR, into: GLASS)

    assert_in_delta 0.0, rp, 1e-6
    assert_in_delta 56.31, BREWSTER, 1e-2
  end

  def test_s_polarised_light_does_not_vanish_there
    rs, = share(at: BREWSTER, from: AIR, into: GLASS)

    assert_operator rs, :>, 0.1
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
      rs, rp, = share(at: degrees, from: AIR, into: GLASS)

      assert_operator rs, :>=, rp - 1e-9, "failed at #{degrees} deg"
    end
  end

  def test_unpolarised_is_the_mean_of_the_two
    rs, rp, r = share(at: 40, from: AIR, into: GLASS)

    assert_in_delta (rs + rp) / 2, r, 1e-9
  end

  private

  BREWSTER = Math.atan(GLASS / AIR).in_degrees

  def share(at:, from:, into:)
    interface = Surface.new(i: at.deg, mu1: from, mu2: into)
    interface.solve(:rr, guess: 0.4)

    %i[rs rp r].map { |part| interface.solve(part, guess: 0.1) }
  end
end
