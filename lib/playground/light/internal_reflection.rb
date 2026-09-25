require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Internal Reflection"
  question "What happens to the light that is not refracted?"
  description "It turns back into the water, and past this angle that is all of the light: the surface is a mirror. Slide down and the other ray returns, because some of it turns back at every angle."

  input :i, default: 60.deg
  input(:mu_1) { REFRACTIVE_MEDIA.fetch("water") }
  input(:mu_2) { REFRACTIVE_MEDIA.fetch("air") }

  output :r_l
  output :r_r
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media "water", "air"
    ray "incident",  arriving_at: :i,  angle: true
    ray "reflected", leaving_at:  :r_l, angle: true
    ray "refracted", crossing_at: :r_r, angle: true, unless: :no_refracted_ray
    note "all of it turns back", when: :no_refracted_ray
  end
end
