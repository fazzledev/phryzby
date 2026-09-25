require_relative "../../light/reflection"
require_relative "../../light/relative_index"
require_relative "../../light/picture"

RATIO = 0.25..4.0

play_with Reflection, RelativeIndex do
  title "Relative Refractive Index"
  question "Do both numbers matter, or only what they come to?"
  description "Only what they come to. One file says so — mu_21 is mu_2 over mu_1 — and here the first medium is called 1, which leaves the second one standing for the pair."

  input :mu_21, RATIO, default: 0.75, marks: { "critical" => 0.5, "alike" => 1.0 }

  input(:i)   { 30.deg }
  input(:mu_1) { 1.0 }
  input(:mu_2) { mu_21 }

  output("critical", in: :deg) { asking(:i, r_r: 90.deg) }
  output :r_r
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    surface across: :mu_21
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :r_l
    ray "refracted", crossing_at: :r_r, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, r_r: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
