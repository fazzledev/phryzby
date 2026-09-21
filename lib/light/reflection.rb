require_relative "optics"

module Reflection
  extend Physics::Law

  uses Optics, :i, :rl

  equation(:law_of_reflection) { i == rl }
end

class Surface < Physics::Scenario
  include Reflection

  def angle_of_reflection = solve(:rl)
end
