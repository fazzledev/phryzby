require_relative "refraction"

module Reflectance
  extend Physics::Law

  RIGHT_ANGLE = 0.0..(Math::PI / 2)
  INDEX = 1.0..4.0
  FRACTION = 0.0..1.0

  variable :angle_of_incidence,                alias: :i,   within: RIGHT_ANGLE
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: INDEX
  variable :refractive_index_of_second_medium, alias: :mu2, within: INDEX

  variable :reflectance_s_polarised, alias: :rs, within: FRACTION
  variable :reflectance_p_polarised, alias: :rp, within: FRACTION
  variable :reflectance,             alias: :r,  within: FRACTION

  equation(:s_polarised) do
    rs == ((mu1 * cos(i) - mu2 * cos(rr)) / (mu1 * cos(i) + mu2 * cos(rr))) ** 2
  end

  equation(:p_polarised) do
    rp == ((mu1 * cos(rr) - mu2 * cos(i)) / (mu1 * cos(rr) + mu2 * cos(i))) ** 2
  end

  equation(:unpolarised) { r == (rs + rp) / 2 }
end

class Interface
  include Reflectance
end
