require_relative "../physics"

# Throw something and let go of it. Nothing pushes it after that, so where it
# goes is settled the instant it leaves your hand — by how fast it left, the
# angle it left at, and how hard the world pulls down.
module Projectile
  extend Physics::Law

  quantity :speed,           variable: :u
  quantity :angle_of_throw,  variable: :theta_0, within: Physics::A_RIGHT_ANGLE
  quantity :gravity,         variable: :g

  quantity :range,           variable: :R
  quantity :peak,            variable: :H
  quantity :time_of_flight,  variable: :T

  equation(:horizontal_range) { R == u**2 * sin(2 * theta_0) / g }
  equation(:maximum_height)   { H == (u * sin(theta_0))**2 / (2 * g) }
  equation(:time_of_flight)   { T == 2 * u * sin(theta_0) / g }
end
