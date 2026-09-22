require_relative "refraction"

module Reflectance
  extend Physics::Law

  include Refraction

  quantity :reflectance_s_polarised, variable: :rs
  quantity :reflectance_p_polarised, variable: :rp
  quantity :reflectance,             variable: :r

  equation(:s_polarised) do
    rs == ((mu1 * cos(i) - mu2 * cos(rr)) / (mu1 * cos(i) + mu2 * cos(rr))) ** 2
  end

  equation(:p_polarised) do
    rp == ((mu1 * cos(rr) - mu2 * cos(i)) / (mu1 * cos(rr) + mu2 * cos(i))) ** 2
  end

  equation(:unpolarised) { r == (rs + rp) / 2 }
end
