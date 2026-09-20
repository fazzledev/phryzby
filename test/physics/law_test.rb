require "minitest/autorun"
require_relative "../../lib/physics"

class LawTest < Minitest::Test
  CATALOGUE = Module.new do
    extend Physics::Law

    variable :angle, alias: :a, within: 0.0..1.5
    variable :width, alias: :w, within: 0.0..9.0
    variable :depth, alias: :d
  end

  def test_a_law_is_not_a_model
    refute_operator law { }, :respond_to?, :new
  end

  def test_including_a_law_gives_the_model_its_equations
    model = Class.new(Physics::Model) { include LawTest.trivial }

    assert model.equations.key?(:trivial)
  end

  def test_uses_brings_the_alias_with_it
    borrower = law { uses CATALOGUE, :a }

    assert_equal :angle, borrower.variables.fetch(:a)
    assert_equal :angle, borrower.variables.fetch(:angle)
  end

  def test_uses_brings_the_domain_with_it
    assert_equal 0.0..1.5, law { uses CATALOGUE, :a }.domains.fetch(:angle)
  end

  def test_a_quantity_with_no_domain_declares_none
    refute law { uses CATALOGUE, :d }.domains.key?(:depth)
  end

  def test_uses_takes_only_what_it_names
    borrower = law { uses CATALOGUE, :a }

    refute borrower.variables.key?(:w)
    refute borrower.variables.key?(:width)
  end

  def test_a_quantity_that_is_not_in_the_catalogue_is_an_error
    assert_raises(KeyError) { law { uses CATALOGUE, :nonesuch } }
  end

  def test_two_laws_can_name_the_same_quantity
    model = Class.new(Physics::Model)
    model.include(law { uses CATALOGUE, :a, :w })
    model.include(law { uses CATALOGUE, :a, :d })

    assert_equal %i[angle width depth], model.variables.values.uniq
  end

  def self.trivial
    law { variable :thing; equation(:trivial) { thing == 1 } }
  end

  def self.law(&declarations)
    Module.new do
      extend Physics::Law
      instance_eval(&declarations)
    end
  end

  private

  def law(&declarations) = self.class.law(&declarations)
end
