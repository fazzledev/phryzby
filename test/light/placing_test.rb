require "minitest/autorun"
require_relative "../../lib/light/placing"

class PlacingTest < Minitest::Test
  def label(text, spots, fixed: false)
    { text: text, spots: spots, colour: "black", fixed: fixed }
  end

  def where(svg) = svg.scan(/x="([-\d.]+)" y="([-\d.]+)"/).map { |x, y| [ x.to_f, y.to_f ] }

  def test_a_label_takes_its_first_choice_when_it_is_free
    placed = Light::Placing.new(300, 200).resolve([ label("one", [ [ 50, 50, "start" ] ]) ])

    assert_equal [ [ 50.0, 50.0 ] ], where(placed.join)
  end

  def test_a_second_label_moves_out_of_the_first_one_s_way
    placed = Light::Placing.new(300, 200).resolve([
      label("one", [ [ 50, 50, "start" ] ]),
      label("two", [ [ 50, 50, "start" ], [ 50, 90, "start" ] ]),
    ])

    assert_equal [ [ 50.0, 50.0 ], [ 50.0, 90.0 ] ], where(placed.join)
  end

  def test_a_spot_that_is_remembered_is_taken_again
    first = Light::Placing.new(300, 200)
    first.resolve([ label("one", [ [ 50, 50, "start" ] ]),
                    label("two", [ [ 50, 50, "start" ], [ 50, 90, "start" ] ]) ])

    again = Light::Placing.new(300, 200, first.settled)
    placed = again.resolve([ label("one", [ [ 50, 50, "start" ] ]),
                             label("two", [ [ 50, 50, "start" ], [ 50, 90, "start" ] ]) ])

    assert_equal [ [ 50.0, 50.0 ], [ 50.0, 90.0 ] ], where(placed.join)
  end

  # Remembering where a label was is no reason to put it somewhere occupied.
  def test_a_remembered_spot_is_not_taken_when_something_is_already_there
    settled = { "last" => [ 50, 90, "start" ] }
    placed = Light::Placing.new(300, 200, settled).resolve([
      label("one", [ [ 50, 50, "start" ] ]),
      label("two", [ [ 50, 90, "start" ] ]),
      label("last", [ [ 50, 50, "start" ], [ 50, 90, "start" ], [ 50, 130, "start" ] ]),
    ])

    assert_equal [ 50.0, 130.0 ], where(placed.join).last
  end

  def test_what_does_not_move_claims_its_place_before_what_does
    placed = Light::Placing.new(300, 200).resolve([
      label("carried", [ [ 50, 50, "start" ], [ 50, 90, "start" ] ]),
      label("fixed", [ [ 50, 50, "start" ] ], fixed: true),
    ])

    # Resolved fixed-first, so that is the order they come back in too.
    assert_equal [ [ 50.0, 50.0 ], [ 50.0, 90.0 ] ], where(placed.join)
  end
end
