# How hard each world pulls, in metres per second per second, at its surface.
# Every chapter that lets the pull be chosen chooses from here, so the same
# name always means the same number.
GRAVITY = { "moon" => 1.62, "mars" => 3.72, "earth" => 9.81, "jupiter" => 24.79 }.freeze
