require_relative "../../light/reflection"
require_relative "../../light/refractive_index"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..4.0
MEDIA = { "air" => 1.0, "water" => 1.33, "glass" => 1.5, "diamond" => 2.42,
          "cinnabar" => 3.2, "silicon" => 3.9 }.freeze

play_with Reflection, RefractiveIndex do
  title "Refractive index"
  description "What each medium does to light is one number, and only the ratio of the two ever shows."

  input :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  input :mu1, INDEX, step: 0.01, at: 1.0, as: "μ₁ first", marks: MEDIA
  input :mu2, INDEX, step: 0.01, at: 1.5, as: "μ₂ second", marks: MEDIA

  output :mu21, in: :number
  output("sin i ÷ sin rr", in: :number) { Math.sin(solve(:i)) / Math.sin(solve(:rr)) }
  output :rr, in: :degrees
  output :no_refracted_ray, in: :plain, alarm: true

  draw Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "no refracted ray", when: :no_refracted_ray
  end
end
