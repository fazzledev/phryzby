require "minitest/autorun"
require_relative "../chapters"

class PlaygroundTest < Minitest::Test
  APART = 0.chr

  def playing = INDEXED
  def opening = playing.opening

  def test_a_scenario_is_still_a_scenario
    assert_in_delta 41.6823, playing.posing(**opening).solve(:rr).in_degrees, 1e-3
  end

  def test_it_starts_where_it_was_told_to
    assert_in_delta 30.0, opening.fetch(:i).in_degrees, 1e-9
    assert_in_delta 1.0, opening.fetch(:mu2), 1e-9
  end

  def test_a_control_is_drawn_for_every_quantity_varied
    controls = playing.controls

    assert_equal 3, controls.scan(/data-input=/).size
    assert_includes controls, 'data-input="i"'
  end

  def test_a_reading_is_shown_in_the_unit_it_was_asked_for
    assert_includes playing.readouts(opening), "41.68°"
  end

  def test_a_sideways_question_poses_the_situation_afresh
    here = playing.posing(**opening.merge(mu1: 1.5, mu2: 1.0))
    here.solve(:rl)

    assert_in_delta 41.8103, here.asking(:i, rr: 90.deg).in_degrees, 1e-3
  end

  def test_what_was_solved_along_the_way_is_not_carried_into_it
    here = playing.posing(**opening.merge(mu1: 1.5, mu2: 1.0))
    here.solve(:rr)
    here.solve(:rl)

    refute_in_delta here[:i].in_degrees, here.asking(:i, rr: 90.deg).in_degrees, 1e-6
  end

  def test_the_situation_it_was_asked_of_is_left_alone
    here = playing.posing(**opening.merge(mu1: 1.5, mu2: 1.0))
    here.asking(:i, rr: 90.deg)

    assert_in_delta 30.0, here[:i].in_degrees, 1e-9
  end

  def test_a_reading_that_cannot_be_worked_out_says_so
    assert_includes playing.readouts(opening.merge(mu1: 1.5, mu2: 1.0, i: 60.deg)), "—"
  end

  def test_the_law_states_itself_and_nothing_else_does
    assert_includes playing.stated, "<math"
    refute_includes playing.stated, "<h1>"
    refute_includes playing.to_html(opening), "<h1>"
  end

  def test_the_chapter_names_itself_apart_from_all_three
    assert_includes playing.heading, "<h1>Refractive Index"
    assert_includes playing.heading, "class=\"lede\""
  end

  def test_moving_a_control_gives_back_the_picture_the_numbers_and_the_labels
    picture, readouts, labels = playing.moved(opening.merge(i: 70.deg)).split(APART)

    assert_includes picture, "<svg"
    assert_includes readouts, "class=\"val\""
    assert_includes labels, "70.00°"
  end

  def test_a_quantity_is_written_the_way_the_law_writes_it
    assert_equal :mu1, playing.written_for(:refractive_index_of_first_medium)
    assert_equal :i, playing.written_for(:angle_of_incidence)
  end
  def test_a_marked_input_draws_a_notch_at_each_mark
    controls = playing.controls

    assert_equal 12, controls.scan(/class="mark"/).size
    assert_includes controls, 'data-set="1.5" data-for="mu1"'
  end

  # Laid along the run the handle actually travels, not the whole width.
  def test_a_notch_sits_where_its_value_falls_along_the_track
    controls = playing.controls

    assert_includes controls, "* 0.0)"
    assert_includes controls, "* 0.4733)"
    assert_includes controls, "* 0.9667)"
  end

  def test_an_unmarked_input_draws_none
    incidence = playing.controls[/<label for="i".*?<\/div><output/m]

    refute_includes incidence, "mark"
  end

  def test_a_reading_says_what_it_is_sitting_on
    _, _, labels = playing.moved(opening.merge(mu2: 2.42)).split(APART)

    assert_includes labels, "2.42<small>diamond</small>"
  end

  def test_and_says_nothing_between_them
    _, _, labels = playing.moved(opening.merge(mu2: 2.0)).split(APART)
    mu2 = labels.split(2.chr).find { |pair| pair.start_with?("mu2") }

    refute_includes mu2, "<small>"
  end

end
