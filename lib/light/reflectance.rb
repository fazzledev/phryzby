require_relative "refraction"

# How much, rather than which way.
#
# The two previous laws say where the light goes and say nothing about how it
# divides. Fresnel gives the shares, and they depend on polarisation — so there
# are two equations and an average for ordinary unpolarised light.
#
# Inheriting Refraction means one object now holds the whole interface: ask it
# for the refracted angle and it uses Snell, then ask it for a share and it
# uses that answer. The solver picks whichever equation the question needs.
#
# Two well-known facts fall out of these rather than being stated anywhere:
#   - at the critical angle the reflected share reaches 1, which is what the
#     "total" in total internal reflection means
#   - at Brewster's angle the p-polarised share reaches 0, which is why
#     polarised sunglasses cut glare off water
#
#   ruby test/light/reflectance_test.rb

class Reflectance < Refraction
  FRACTION = 0.0..1.0

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
