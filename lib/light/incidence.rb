require_relative "../physics"

module Incidence
  extend Physics::Quantities


  quantity :angle_of_incidence, variable: :i, within: Physics::A_RIGHT_ANGLE
end
