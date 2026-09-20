require_relative "reflection"

# What happens to the rest of the light. A ray meeting an interface does both
# things at once: some comes back at the angle the previous chapter gives, and
# the rest crosses over and bends by the ratio of the two refractive indices.
#
# Refraction inherits Reflection, so this file states only what is new — the
# law of reflection still holds here and is still solvable.
#
# It is also the first law with a branch problem. `sin` is periodic, so Snell
# has infinitely many roots and only one of them is an angle light can take.
# That is what `within:` is for: it tells the solver which branch is physical,
# and without it Newton's method will happily return a root several turns away.
#
#   ruby test/light/refraction_test.rb

class Refraction < Reflection
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: 1.0..4.0
  variable :refractive_index_of_second_medium, alias: :mu2, within: 1.0..4.0

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  # Leaving a dense medium for a thin one, past a certain angle, Snell asks for
  # a sine greater than one. There is no refracted ray at all: it is all
  # reflection, which is how an optical fibre keeps light inside itself.
  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end
