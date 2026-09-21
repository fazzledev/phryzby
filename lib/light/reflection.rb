require_relative "incidence"

module Reflection
  extend Physics::Law
  include Incidence

  variable :angle_of_reflection, alias: :rl, within: Physics::A_RIGHT_ANGLE

  equation(:law_of_reflection) { i == rl }
end
