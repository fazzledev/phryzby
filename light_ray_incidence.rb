require_relative "physics_dsl"

# The law, as you would write it on a board.

class LightRayIncidence < Physics::Model
  RIGHT_ANGLE = 0.0..(Math::PI / 2)

  variable :angle_of_incidence,                alias: :i,   within: RIGHT_ANGLE
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :angle_of_reflection,               alias: :rl,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: 1.0..4.0
  variable :refractive_index_of_second_medium, alias: :mu2, within: 1.0..4.0

  equation(:snells_law)        { mu2 / mu1 == sin(i) / sin(rr) }
  equation(:law_of_reflection) { i == rl }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end

if __FILE__ == $PROGRAM_NAME
  puts "Air into glass, 30 degrees in"
  ray = LightRayIncidence.new(i: 30.deg, mu1: 1.0, mu2: 1.5)
  ray.solve(:rr, guess: 0.3)
  ray.solve(:rl, guess: 0.3)
  puts "  refraction  #{ray[:rr].in_degrees.round(2)} deg"
  puts "  reflection  #{ray[:rl].in_degrees.round(2)} deg"
  puts "  snell holds #{ray.holds?(:snells_law)}"
  puts "  TIR         #{ray.satisfies?(:total_internal_reflection)}"

  puts
  puts "Glass into air, 50 degrees in — past the critical angle"
  trapped = LightRayIncidence.new(i: 50.deg, mu1: 1.5, mu2: 1.0)
  puts "  TIR         #{trapped.satisfies?(:total_internal_reflection)}"
  puts "  critical    #{Math.asin(1.0 / 1.5).in_degrees.round(2)} deg"
end
