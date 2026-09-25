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
  quantity :peak,            variable: :h
  quantity :time_of_flight,  variable: :t_f

  equation(:horizontal_range) { R == u**2 * sin(2 * theta_0) / g }
  equation(:maximum_height)   { h == (u * sin(theta_0))**2 / (2 * g) }
  equation(:time_of_flight)   { t_f == 2 * u * sin(theta_0) / g }

  # And where it is part way through. A moment cannot be slid from nought to
  # the end of the flight, because how long the flight lasts is itself
  # something the law works out; a part of it can be, and the moment follows.
  quantity :part_of_the_flight, variable: :k
  quantity :elapsed,            variable: :t

  quantity :distance_out,    variable: :x
  quantity :height,          variable: :y
  quantity :velocity_across, variable: :v_x
  quantity :velocity_up,     variable: :v_y
  quantity :angle_of_travel, variable: :theta

  equation(:elapsed_time) { t == k * t_f }

  equation(:horizontal_displacement) { x == u * cos(theta_0) * t }
  equation(:vertical_displacement)   { y == u * sin(theta_0) * t - g * t**2 / 2 }

  equation(:horizontal_velocity) { v_x == u * cos(theta_0) }
  equation(:vertical_velocity)   { v_y == u * sin(theta_0) - g * t }

  # Which way it is going now. This is the angle, plainly: the one the throw
  # left at is the special case, taken at nought seconds, and that is the one
  # carrying the mark. It reads the angle it was thrown at while it is still
  # climbing, nought at the top, and the same angle below level coming down.
  equation(:direction_of_travel) { theta == atan(v_y / v_x) }
end
