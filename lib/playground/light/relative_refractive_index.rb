require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/picture"

RATIO = 0.25..4.0

play_with Reflection, Refraction do
  title "Relative Refractive Index"
  question "What do those angles have in common?"
  description "One number each, and the law knows nothing else about the pair: not which two media make it, only what the two of them come to together."

  input :mu21, RATIO, default: 0.75, marks: { "critical" => 0.5, "alike" => 1.0 }

  input(:i) { 30.deg }

  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    surface across: :mu21
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
