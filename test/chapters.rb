# A page loads one playground, so `Physics.playground` answers with whichever
# arrived last. The suite loads them all, and names each one as it arrives.
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

require_relative "../lib/playground/light/refractive_index"
INDEXED = Physics.playground
