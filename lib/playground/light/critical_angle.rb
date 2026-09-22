require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg

play_with Reflection, Refraction do
  title "Critical angle"
  description "Leaving a denser medium there is an angle past which nothing gets out, and nothing here says what it is."

  input  :i,    ANGLE, step: FINELY, default: 30.deg, as: "incidence"
  choose :from, REFRACTIVE_MEDIA, default: "glass"
  choose :into, REFRACTIVE_MEDIA, default: "air"

  given(:mu21) { into / from }

  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media :from, :into
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "no refracted ray", when: :no_refracted_ray
  end
end
