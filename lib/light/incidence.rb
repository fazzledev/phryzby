require_relative "../physics"

module Incidence
  extend Physics::Quantities

  called "Incidence"
  about "a quantity, and no law at all"
  describes "A ray arrives at a surface at some angle. That is the whole chapter: one quantity, its full name, the short name the equations will use, and the branch it lives on. There is no equation here, so there is nothing to solve — and that turns out to be the clearest way to see what the rest of the engine is doing."

  quantity :angle_of_incidence, variable: :i, within: Physics::A_RIGHT_ANGLE
end
