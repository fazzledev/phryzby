require_relative "../physics"

# Throw something and let go of it. Nothing pushes it after that, so where it
# goes is settled the instant it leaves your hand — by how fast it left, the
# angle it left at, and how hard the world pulls down.
module Projectile
  extend Physics::Law

  quantity :speed,           variable: :u
  quantity :angle_of_throw,  variable: :theta_0, within: Physics::A_RIGHT_ANGLE
  quantity :gravity,         variable: :g

  # A throw at an angle is two throws at once: one along the ground, which
  # nothing interferes with, and one straight up, which gravity spends. Every
  # question below is really about one or the other.
  quantity :speed_across,    variable: :u_x
  quantity :speed_up,        variable: :u_y

  equation(:horizontal_component) { u_x == u * cos(theta_0) }
  equation(:vertical_component)   { u_y == u * sin(theta_0) }

  quantity :range,           variable: :R
  quantity :peak,            variable: :H
  quantity :time_of_flight,  variable: :T

  # How far it got is how fast it was going along the ground times how long it
  # was off it. The closed form a book prints — u squared sin two theta over g
  # — is this with the components written out and a double angle collected up.
  equation(:horizontal_range) { R == u_x * T }
  equation(:maximum_height)   { H == u_y**2 / (2 * g) }
  equation(:time_of_flight)   { T == 2 * u_y / g }
end
