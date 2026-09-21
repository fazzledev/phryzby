require "minitest/autorun"
require_relative "../../lib/physics"

class LawTest < Minitest::Test
  def test_a_law_is_not_a_model
    refute_operator law { }, :respond_to?, :new
  end

  def test_including_a_law_gives_the_model_its_equations
    model = Class.new(Physics::Scenario) { include LawTest.trivial }

    assert model.equations.key?(:trivial)
  end

  def test_two_laws_can_name_the_same_quantity
    model = Class.new(Physics::Scenario)
    model.include(law { variable :angle, alias: :a; variable :width, alias: :w })
    model.include(law { variable :angle, alias: :a; variable :depth, alias: :d })

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
