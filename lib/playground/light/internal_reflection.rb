require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Internal Reflection"
  question "What happens to the light that is not refracted?"
  description "Back into the water. Some of the light turns back at every angle, and past the angle where the other one goes it is all that is left."

  input :i, default: 30.deg
  input(:mu21) { REFRACTIVE_MEDIA.fetch("air") / REFRACTIVE_MEDIA.fetch("water") }

  output :rl
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media "water", "air"
    ray "incident",  arriving_at: :i,  angle: true
    ray "reflected", leaving_at:  :rl, angle: true
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    note "all of it turns back", when: :no_refracted_ray
  end
end
