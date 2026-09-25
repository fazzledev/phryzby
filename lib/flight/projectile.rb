require_relative "../physics"

# Throw something and let go of it. Nothing pushes it after that, so where it
# goes is settled the instant it leaves your hand — by how fast it left, the
# angle it left at, and how hard the world pulls down.
module Projectile
  extend Physics::Law

  quantity :speed,          variable: :u
  quantity :angle_of_throw, variable: :theta, within: Physics::A_RIGHT_ANGLE
  quantity :gravity,        variable: :g

  quantity :range,          variable: :r
  quantity :peak,           variable: :h
  quantity :time_of_flight, variable: :t

  equation(:how_far)  { r == u**2 * sin(2 * theta) / g }
  equation(:how_high) { h == (u * sin(theta))**2 / (2 * g) }
  equation(:how_long) { t == 2 * u * sin(theta) / g }

  # And where it is part way through. A moment cannot be slid from nought to
  # the end of the flight, because how long the flight is depends on the
  # throw; a part of it can, and the moment follows from that.
  quantity :part_of_the_flight, variable: :k
  quantity :elapsed,            variable: :tau

  quantity :distance_out, variable: :x
  quantity :height,       variable: :y
  quantity :speed_out,    variable: :sx
  quantity :speed_up,     variable: :sy

  equation(:the_moment) { tau == k * t }

  equation(:carried) { x == u * cos(theta) * tau }
  equation(:lifted)  { y == u * sin(theta) * tau - g * tau**2 / 2 }

  equation(:steady)  { sx == u * cos(theta) }
  equation(:slowing) { sy == u * sin(theta) - g * tau }
end
