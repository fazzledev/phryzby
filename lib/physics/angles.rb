module Physics
  A_RIGHT_ANGLE = 0.0..(Math::PI / 2)
end

class Numeric
  def deg = self * Math::PI / 180.0
  def in_degrees = self * 180.0 / Math::PI
end
