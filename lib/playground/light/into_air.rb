require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Into Air"
  question "Is that angle water's, or does every medium have one?"
  description "Every medium has one of its own, and the denser the medium the sooner it stops letting light out."

  input :from, REFRACTIVE_MEDIA, default: "water"

  input(:i)    { 30.deg }
  input(:mu21) { REFRACTIVE_MEDIA.fetch("air") / from }

  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media :from, "air"
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
