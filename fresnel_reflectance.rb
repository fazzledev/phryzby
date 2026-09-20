require_relative "physics_dsl"

# How much of the light comes back, rather than which way it goes.
#
# Snell's law says nothing about intensity: at every interface some light
# reflects and the rest refracts. Fresnel says how the two shares split, and
# the split depends on polarisation — so there are two equations and an
# average for ordinary unpolarised light.
#
# Two things fall out of these rather than being stated:
#   - at the critical angle the reflected share reaches 1, which is what the
#     "total" in total internal reflection means
#   - at Brewster's angle the p-polarised share reaches 0, which is why
#     polarised sunglasses cut glare off water

class FresnelReflectance < Physics::Model
  FRACTION = 0.0..1.0

  variable :angle_of_incidence,                alias: :i,   within: 0.0..(Math::PI / 2)
  variable :angle_of_refraction,               alias: :rr,  within: 0.0..(Math::PI / 2)
  variable :refractive_index_of_first_medium,  alias: :mu1, within: 1.0..4.0
  variable :refractive_index_of_second_medium, alias: :mu2, within: 1.0..4.0

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
