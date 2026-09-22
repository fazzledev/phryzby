# A page loads one playground, so `Physics.playground` answers with whichever
# arrived last. The suite loads them all, and names each one as it arrives.
require_relative "../lib/playground/light/refraction"
CHOOSING = Physics.playground

require_relative "../lib/playground/light/critical_angle"
CRITICAL = Physics.playground

require_relative "../lib/playground/light/refractive_index"
INDEXED = Physics.playground
