require_relative "../../light/reflection"
require_relative "../../light/reflectance"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

INDEX = 1.0..4.0

play_with Reflection, RefractiveIndex, Reflectance do
  title "Reflectance"
  question "How much of the light gets through?"
  description "It depends on the angle, and on polarisation: the two polarisations are reflected in quite different measure, and at one angle one of them is not reflected at all."

  input :i, default: 50.deg
  input :mu1, INDEX, default: 1.0, marks: REFRACTIVE_MEDIA
  input :mu2, INDEX, default: 1.5, marks: REFRACTIVE_MEDIA

  output :rr
  output :no_refracted_ray, alarm: true
  output :rs, in: :percent
  output :rp, in: :percent
  output :r,  in: :percent
  output("refracted", in: :percent) { 1.0 - solve(:r) }

  draw Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, angle: true,
        weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "no refracted ray — Fresnel has nothing to say", when: :no_refracted_ray
  end
end
