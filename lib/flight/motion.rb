require_relative "projectile"

# Where it is while it is still going. The chapter before this one asks three
# questions about the whole flight and gets three answers; this asks where the
# thing actually is, at a moment, and the three answers turn out to be what
# these say at the moments that matter.
#
# A moment cannot be slid from nought to the end of the flight, because how
# long the flight lasts is itself something the law works out. A part of it
# can be, and the moment follows from that.
module Motion
  extend Physics::Law

  include Projectile

  quantity :part_of_the_flight, variable: :k
  quantity :elapsed,            variable: :t

  quantity :distance_out,    variable: :x
  quantity :height,          variable: :y
  quantity :velocity_across, variable: :v_x
  quantity :velocity_up,     variable: :v_y
  quantity :angle_of_travel, variable: :theta

  equation(:elapsed_time) { t == k * T }

  equation(:horizontal_displacement) { x == u * cos(theta_0) * t }
  equation(:vertical_displacement)   { y == u * sin(theta_0) * t - g * t**2 / 2 }

  equation(:horizontal_velocity) { v_x == u * cos(theta_0) }
  equation(:vertical_velocity)   { v_y == u * sin(theta_0) - g * t }

  # Which way it is going now. This is the angle, plainly: the one the throw
  # left at is the special case, taken at nought seconds, and that is the one
  # carrying the mark.
  equation(:direction_of_travel) { theta == atan(v_y / v_x) }
end
