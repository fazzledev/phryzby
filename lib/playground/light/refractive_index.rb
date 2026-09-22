require_relative "../../light/reflection"
require_relative "../../light/refractive_index"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

INDEX = 1.0..4.0

play_with Reflection, RefractiveIndex do
  title "Refractive Index"
  description "The same crossing, with the number behind it taken apart. What each medium does to light is one number, and only the ratio of the two ever shows."

  input :i, default: 30.deg
  input :mu1, INDEX, default: 1.33, marks: REFRACTIVE_MEDIA
  input :mu2, INDEX, default: 1.0, marks: REFRACTIVE_MEDIA

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
