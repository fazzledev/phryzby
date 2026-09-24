# A page loads one playground, so `Physics.playground` answers with whichever
# arrived last. The suite loads them all, and names each one as it arrives.
require_relative "../lib/playground/flight/projectile"
THROWN = Physics.playground

require_relative "../lib/playground/light/refraction"
BENDING = Physics.playground

require_relative "../lib/playground/light/water_to_air"
OUT_OF_WATER = Physics.playground

require_relative "../lib/playground/light/any_two_media"
CHOOSING = Physics.playground

require_relative "../lib/playground/light/internal_reflection"
INTERNAL = Physics.playground

require_relative "../lib/playground/light/critical_angle"
CRITICAL = Physics.playground

require_relative "../lib/playground/light/into_air"
INTO_AIR = Physics.playground

require_relative "../lib/playground/light/relative_refractive_index"
RATIOED = Physics.playground

require_relative "../lib/playground/light/refractive_index"
INDEXED = Physics.playground

# The machinery tests draw rather than read, and want every quantity the
# picture can be told about on a control. A chapter holds whatever it is not
# about, and which that is changes as the book is written; this does not.
play_with Reflection, RelativeIndex do
  title "Drawing"
  description "Every quantity the picture can be told about, on a control."

  input :i, default: 30.deg
  input :mu1, 1.0..4.0, default: 1.33, marks: REFRACTIVE_MEDIA
  input :mu2, 1.0..4.0, default: 1.0, marks: REFRACTIVE_MEDIA

  output :mu21
  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
DRAWING = Physics.playground
