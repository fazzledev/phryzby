require_relative "../physics_dsl"

# The first law, and the smallest one that shows what the DSL is for.
#
# Inside the equation block `i` and `rl` are not numbers — they are nodes in an
# expression tree. So `==` does not answer true or false, it builds an equation
# and hands it back. Nothing is computed until something asks for a value.
#
#   ruby test/light/reflection_test.rb

class Reflection < Physics::Model
  RIGHT_ANGLE = 0.0..(Math::PI / 2)

  variable :angle_of_incidence,  alias: :i,  within: RIGHT_ANGLE
  variable :angle_of_reflection, alias: :rl, within: RIGHT_ANGLE

  equation(:law_of_reflection) { i == rl }
end
