require_relative "../../light/reflection"
require_relative "../../light/reflectance"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Split = Physics::Scenario[Reflection, Refraction, Reflectance].showing do
  titled Reflectance

  vary :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  vary :mu1, INDEX, step: 0.01, at: 1.0, as: "μ₁ first"
  vary :mu2, INDEX, step: 0.01, at: 1.5, as: "μ₂ second"

  show :rr, in: :degrees
  show :no_refracted_ray, in: :plain, alarm: true
  show :rs, in: :percent
  show :rp, in: :percent
  show :r,  in: :percent
  show("refracted", in: :percent) { 1.0 - solve(:r) }

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    note "no refracted ray — Fresnel has nothing to say", when: :no_refracted_ray
  end
end
