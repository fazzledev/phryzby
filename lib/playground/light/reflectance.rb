require_relative "../../light/reflection"
require_relative "../../light/reflectance"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..4.0
MEDIA = { "air" => 1.0, "water" => 1.33, "glass" => 1.5, "diamond" => 2.42,
          "cinnabar" => 3.2, "silicon" => 3.9 }.freeze

play_with Reflection, Refraction, Reflectance do
  title "Reflectance"
  description "At any boundary some light turns back and the rest crosses. How much of each depends on the angle, and on polarisation."

  input :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  input :mu1, INDEX, step: 0.01, at: 1.0, as: "μ₁ first", marks: MEDIA
  input :mu2, INDEX, step: 0.01, at: 1.5, as: "μ₂ second", marks: MEDIA

  output :rr, in: :degrees
  output :no_refracted_ray, in: :plain, alarm: true
  output :rs, in: :percent
  output :rp, in: :percent
  output :r,  in: :percent
  output("refracted", in: :percent) { 1.0 - solve(:r) }

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, angle: true,
        weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "no refracted ray — Fresnel has nothing to say", when: :no_refracted_ray
  end
end
