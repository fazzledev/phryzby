require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Into Air"
  question "Does every medium have its own angle?"
  description "Every medium has one of its own, and the denser the medium the sooner it stops letting light out."

  input :from, REFRACTIVE_MEDIA, default: "water"

  input(:i)    { 30.deg }
  input(:mu_1) { from }
  input(:mu_2) { REFRACTIVE_MEDIA.fetch("air") }

  output("critical", in: :deg) { asking(:i, r_r: 90.deg) }
  output :r_r
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media :from, "air"
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :r_l
    ray "refracted", crossing_at: :r_r, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, r_r: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
