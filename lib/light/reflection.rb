require_relative "incidence"

module Reflection
  extend Physics::Law

  called "Reflection"
  about "the angle out is the angle in"
  describes "The smallest law there is. Inside the equation block <code>i</code> and <code>rl</code> are not numbers — they are nodes in an expression tree, so <code>==</code> does not answer true or false, it builds an equation and hands it back."
  include Incidence

  quantity :angle_of_reflection, variable: :rl, within: Physics::A_RIGHT_ANGLE

  equation(:law_of_reflection) { i == rl }
end
