require_relative "../physics"

module Reflection
  extend Physics::Law

  variable :angle_of_incidence,  alias: :i,  within: Physics::A_RIGHT_ANGLE
  variable :angle_of_reflection, alias: :rl, within: Physics::A_RIGHT_ANGLE

  equation(:law_of_reflection) { i == rl }
end
