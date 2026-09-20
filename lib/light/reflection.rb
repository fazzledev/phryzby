require_relative "../physics_dsl"

module Reflection
  extend Physics::Law

  RIGHT_ANGLE = 0.0..(Math::PI / 2)

  variable :angle_of_incidence,  alias: :i,  within: RIGHT_ANGLE
  variable :angle_of_reflection, alias: :rl, within: RIGHT_ANGLE

  equation(:law_of_reflection) { i == rl }
end

class Interface < Physics::Model
  include Reflection
end
