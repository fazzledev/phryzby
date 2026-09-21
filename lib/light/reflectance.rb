require_relative "../physics"

module Reflectance
  extend Physics::Law

  variable :angle_of_incidence,  alias: :i,  within: Physics::A_RIGHT_ANGLE
  variable :angle_of_refraction, alias: :rr, within: Physics::A_RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1
  variable :refractive_index_of_second_medium, alias: :mu2
  variable :reflectance_s_polarised, alias: :rs
  variable :reflectance_p_polarised, alias: :rp
  variable :reflectance,             alias: :r

  equation(:s_polarised) do
    rs == ((mu1 * cos(i) - mu2 * cos(rr)) / (mu1 * cos(i) + mu2 * cos(rr))) ** 2
  end

  equation(:p_polarised) do
    rp == ((mu1 * cos(rr) - mu2 * cos(i)) / (mu1 * cos(rr) + mu2 * cos(i))) ** 2
  end

  equation(:unpolarised) { r == (rs + rp) / 2 }
end
