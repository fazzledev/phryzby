require "minitest/autorun"
require_relative "../chapters"
require_relative "../legible"

# The same rule the light chapters are held to, over everything the throw
# chapter's three controls can reach between them.
class FlightLegibleTest < Minitest::Test
  include Legible

  def test_every_throw_this_chapter_can_make_is_legible
    IN_VIEW.keys.each_index do |view|
      GRAVITY.keys.each_index do |world|
        [ 5.0, 18.0, 40.0, 100.0 ].each do |speed|
          (1..89).step(8) do |degrees|
            held = THROWN.opening.merge(world: world, u: speed, theta_0: degrees.deg, in_view: view)
            legible("#{GRAVITY.keys[world]} at #{speed} m/s, #{degrees}°, " \
                    "#{IN_VIEW.keys[view]} in view", THROWN.picture(held, settled: {}))
          end
        end
      end
    end
  end
end
