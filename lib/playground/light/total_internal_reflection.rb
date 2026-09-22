require_relative "../../light/reflection"
require_relative "../../light/total_internal_reflection"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..4.0
MEDIA = { "air" => 1.0, "water" => 1.33, "glass" => 1.5, "diamond" => 2.42,
          "cinnabar" => 3.2, "silicon" => 3.9 }.freeze

play_with Reflection, TotalInternalReflection do
  title "Total internal reflection"
  description "Past a certain angle, light leaving a denser medium cannot cross at all. All of it turns back."

  input :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  input :mu1, INDEX, step: 0.01, at: 1.5, as: "μ₁ first", marks: MEDIA
  input :mu2, INDEX, step: 0.01, at: 1.0, as: "μ₂ second", marks: MEDIA

  output :no_refracted_ray, in: :plain, alarm: true
  output :r, in: :percent
  output("solved from") { satisfies?(:no_refracted_ray) ? ":everything_reflects" : ":unpolarised" }

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, angle: true,
        weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "trapped — every ray turns back", when: :no_refracted_ray
  end
end
