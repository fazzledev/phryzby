require_relative "../../light/reflection"
require_relative "../../light/total_internal_reflection"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

INDEX = 1.0..4.0

play_with Reflection, TotalInternalReflection do
  title "Total Internal Reflection"
  question "What is left past the angle where nothing gets across?"
  description "All of it turns back. Not most of it: the share is exactly one, and it is one because there is nowhere else for the light to go."

  input :i, default: 50.deg
  input :mu1, INDEX, default: 1.5, marks: REFRACTIVE_MEDIA
  input :mu2, INDEX, default: 1.0, marks: REFRACTIVE_MEDIA

  output :no_refracted_ray, alarm: true
  output :r, in: :percent
  output("solved from") { satisfies?(:no_refracted_ray) ? ":everything_reflects" : ":unpolarised" }

  draw Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, angle: true,
        weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "trapped — every ray turns back", when: :no_refracted_ray
  end
end
