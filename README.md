# phryzby

Physics written as Ruby, and still executable.

A law should read the way it is written on a blackboard. So inside an `equation`
block the variables are not numbers — they are expression nodes. `==` on them
builds an equation rather than answering true or false, and the solver finds a
root of `left - right` afterwards.

```ruby
module Refraction
  extend Physics::Law

  uses Optics, :i, :rr, :mu1, :mu2

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end

class Interface < Physics::Model
  include Reflection
  include Refraction
end
```

A quantity is declared once, in `lib/light/optics.rb`, with its symbol and the
branch it lives on. That file is a catalogue, not a law: it extends
`Physics::Quantities`, so it has no equations and cannot be included into a
model to smuggle its whole contents in. A law then says which quantities it mentions — and it
has to name them all, because the equation block is evaluated against the law's
own variables and can see nothing else.

Because the law is stored rather than compiled into a formula, one declaration
solves in any direction. Give it two angles and it names the material:

```ruby
ray = Interface.new(i: 45.deg, rr: 28.9.deg, mu1: 1.0)
ray.solve(:mu2, guess: 1.2).round(2)   # => 1.46, which is silica glass

ray = Interface.new(i: 45.deg, mu1: 1.0, mu2: 1.5)
ray.solve(:rr, guess: 0.4).in_degrees  # => 28.13
```

`within:` is the branch a quantity physically lives on — a refracted angle is
between zero and a right angle, a reflectance is a fraction. It matters: `sin`
is periodic, so without a declared domain a solver is free to return any of the
infinitely many roots of Snell's law, and Newton's method will happily hand you
one several turns away.

## Chapters

A law is a module, not a class, because a law is not a kind of another law.
What the chapters build up is `Interface` — the surface light arrives at — and
each chapter includes one more law into it.

| | | |
|---|---|---|
| 1.1 | `Reflection` | one equation; what it means for `==` to build rather than compare |
| 1.2 | `Refraction` | Snell, declared domains, total internal reflection as a condition |
| 1.3 | `Reflectance` | Fresnel: three equations, and the solver choosing between them |

By the third, one interface holds all of them:
ask it for the refracted angle and it uses Snell, then ask it for a share and
it uses that answer. Nothing tells it which equation to reach for.

Two well-known numbers fall out of Fresnel rather than being stated anywhere:

- reflection reaches 1 exactly at the critical angle, which is what the *total*
  in total internal reflection means
- the p-polarised share reaches 0 at Brewster's angle, which is why polarised
  sunglasses cut glare off water

## The demo

**[Open it](https://fazzle.dev/phryzby/)** — one page per chapter: file tree on
the left, the law in the middle, the demo on the right. Each
downloads CRuby compiled to WebAssembly (about 30 MB, cached across pages) and
`fetch`es the `.rb` files out of this repository, so the page runs the same
bytes the tests run. Edit a law in the page and run it again; delete a `within:`
domain and watch the solver wander off the physical branch.

## Running it

```
ruby test/physics_test.rb               #  8 runs,  17 assertions
ruby test/physics/law_test.rb           #  3 runs,   4 assertions
ruby test/physics/quantities_test.rb    #  7 runs,  10 assertions
ruby test/physics/solver_test.rb        #  7 runs,   7 assertions
ruby test/pythagoras_test.rb            #  8 runs,  10 assertions
ruby test/light/reflection_test.rb      #  7 runs,   7 assertions
ruby test/light/refraction_test.rb      # 14 runs, 106 assertions
ruby test/light/reflectance_test.rb     #  9 runs, 189 assertions
```

No gems, and no comments — the prose is on the pages. Ruby 3.4.

## Layout

```
lib/physics.rb         requires the seven parts below
lib/physics/
  expression.rb        Expr, Const, Var, BinOp, Fn — every operator returns a node
  equation.rb          Equation and Comparison: what a declaration block returns
  scope.rb             the object a declaration block runs against
  quantities.rb        declaring a quantity, and borrowing one with `uses`
  law.rb               Declarations, and Law — a module a model absorbs
  solver.rb            Newton, bisection, and which one to believe
  model.rb             holding values, choosing an equation, solving
  degrees.rb           Numeric#deg and #in_degrees
lib/light/optics.rb    every optical quantity, declared once
lib/light/*.rb         one law per file, plus the Interface that includes it
test/                  mirrors lib/
assets/phryzby.js      the tree, highlighting, the editor, booting CRuby — no build step
assets/phryzby.css
index.html             contents
light/*.html           one page per chapter
```
