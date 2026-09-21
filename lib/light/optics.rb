require_relative "../physics"

module Optics
  extend Physics::Quantities

  RIGHT_ANGLE = 0.0..(Math::PI / 2)
  INDEX = 1.0..4.0
  FRACTION = 0.0..1.0

  variable :angle_of_incidence,                alias: :i,   within: RIGHT_ANGLE
  variable :angle_of_reflection,               alias: :rl,  within: RIGHT_ANGLE
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE

  variable :refractive_index_of_first_medium,  alias: :mu1, within: INDEX
  variable :refractive_index_of_second_medium, alias: :mu2, within: INDEX

  variable :reflectance_s_polarised, alias: :rs, within: FRACTION
  variable :reflectance_p_polarised, alias: :rp, within: FRACTION
  variable :reflectance,             alias: :r,  within: FRACTION
end
