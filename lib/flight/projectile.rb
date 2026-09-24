require_relative "../physics"

# Throw something and let go of it. Nothing pushes it after that, so where it
# goes is settled the instant it leaves your hand — by how fast it left, the
# angle it left at, and how hard the world pulls down.
module Projectile
  extend Physics::Law

  quantity :speed,          variable: :u
  quantity :angle_of_throw, variable: :theta, within: Physics::A_RIGHT_ANGLE
  quantity :gravity,        variable: :g

  quantity :range,          variable: :x
  quantity :peak,           variable: :h
  quantity :time_of_flight, variable: :t

  equation(:how_far)  { x == u**2 * sin(2 * theta) / g }
  equation(:how_high) { h == (u * sin(theta))**2 / (2 * g) }
  equation(:how_long) { t == 2 * u * sin(theta) / g }
end
