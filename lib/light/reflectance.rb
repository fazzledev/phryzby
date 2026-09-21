require_relative "optics"
require_relative "refraction"

module Reflectance
  extend Physics::Law

  uses Optics, :i, :rr, :mu1, :mu2, :rs, :rp, :r

  equation(:s_polarised) do
    rs == ((mu1 * cos(i) - mu2 * cos(rr)) / (mu1 * cos(i) + mu2 * cos(rr))) ** 2
  end

  equation(:p_polarised) do
    rp == ((mu1 * cos(rr) - mu2 * cos(i)) / (mu1 * cos(rr) + mu2 * cos(i))) ** 2
  end

  equation(:unpolarised) { r == (rs + rp) / 2 }
end

class Surface < Physics::Scenario
  include Reflection
  include Refraction
  include Reflectance

  SHARE_GUESS = 0.1

  def s_polarised_share = share(:rs)

  def p_polarised_share = share(:rp)

  def reflected_share
    s_polarised_share
    p_polarised_share
    share(:r)
  end

  def refracted_share = 1.0 - reflected_share

  private

  def share(part)
    angle_of_refraction unless self[:rr]
    solve(part, guess: SHARE_GUESS)
  end
end
