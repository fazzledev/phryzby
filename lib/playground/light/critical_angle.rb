require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Critical Angle"
  question "At what angle does it stop getting out?"
  description "At 48.75°, for water and air, and no new law is needed to say so: it is Snell asked backwards, with the refracted ray lying flat along the surface."

  input :i, default: 30.deg
  input(:mu1) { REFRACTIVE_MEDIA.fetch("water") }
  input(:mu2) { REFRACTIVE_MEDIA.fetch("air") }

  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media "water", "air"
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
