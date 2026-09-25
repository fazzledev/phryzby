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
  quantity :time_of_flight, variable: :tf

  equation(:how_far)  { r == u**2 * sin(2 * theta) / g }
  equation(:how_high) { h == (u * sin(theta))**2 / (2 * g) }
  equation(:how_long) { tf == 2 * u * sin(theta) / g }

  # And where it is part way through. A moment cannot be slid from nought to
  # the end of the flight, because how long the flight lasts is itself
  # something the law works out; a part of it can be, and the moment follows.
  quantity :part_of_the_flight, variable: :k
  quantity :elapsed,            variable: :t

  quantity :distance_out,    variable: :x
  quantity :height,          variable: :y
  quantity :velocity_across, variable: :vx
  quantity :velocity_up,     variable: :vy

  equation(:the_moment) { t == k * tf }

  equation(:carried) { x == u * cos(theta) * t }
  equation(:lifted)  { y == u * sin(theta) * t - g * t**2 / 2 }

  equation(:steady)  { vx == u * cos(theta) }
  equation(:slowing) { vy == u * sin(theta) - g * t }
end
