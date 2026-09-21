require_relative "../physics"

module Incidence
  extend Physics::Law

  variable :angle_of_incidence, alias: :i, within: Physics::A_RIGHT_ANGLE
end
