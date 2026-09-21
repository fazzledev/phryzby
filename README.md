# phryzby

Play with the laws of physics.

You write a law down once, the way it appears on a blackboard, and never
rearrange it — which means you can change it. Say a mirror should turn light by
half the angle it arrives at rather than all of it. Edit that line in the
browser and every answer on the page follows the law you just invented, because
there is no derivation to redo: there was never a formula, only an expression
tree and a root to find.

Inside an `equation` block the names are not numbers — they are nodes in that
tree, so `==` builds an equation rather than answering true or false. Asking is
a separate act: name the unknown, and the solver finds a root of
`left - right`. It never learns what the law says, which is why an invented law
costs exactly what a true one does.

```ruby
module Refraction
  extend Physics::Law

  uses Optics, :i, :rr, :mu1, :mu2

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end
```

That is the whole file. A law is a module and holds no values; nothing composes
laws until a question is asked:

```ruby
glass = Physics::Scenario[Refraction]

glass.new(i: 30.deg, mu1: 1.0, mu2: 1.5).solve(:rr).in_degrees
# => 19.4712, the refracted ray

glass.new(i: 30.deg, rr: 19.4712.deg, mu1: 1.0).solve(:mu2)
# => 1.5000, the material itself

glass.new(rr: 90.deg, mu1: 1.5, mu2: 1.0).solve(:i).in_degrees
# => 41.8103, the critical angle
```

Nothing there was rearranged, and there is no second formula for the critical
angle anywhere in this repository — it is Snell asked with the refracted ray
lying flat along the surface, which is the last angle that still has one.
`Math.asin(1.0 / 1.5).in_degrees` agrees to ten decimal places.

A quantity is declared once, in `lib/light/optics.rb`, with its symbol and the
branch it lives on. That file is a catalogue, not a law: it extends
`Physics::Quantities`, so it has no equations and cannot be included into a
scenario to smuggle its whole contents in. A law then says which quantities it
mentions — and it has to name them all, because the equation block is evaluated
against the law's own variables and can see nothing else.

## Asking for one thing gets you the rest

A scenario names the laws that hold where the question is being asked. It is
not told which equation to use, or in what order:

```ruby
surface = Physics::Scenario[Reflection, Refraction, Reflectance]
                           .new(i: 40.deg, mu1: 1.0, mu2: 1.5)

surface.solve(:r)         # => 0.0457, the reflected share
surface[:rr].in_degrees   # => 25.3740 — Snell, which nobody asked for
```

Fresnel's equations need the refracted angle, which only Snell determines. So
asking for the reflectance reaches back through five equations: the unpolarised
mean needs both polarisations, each of those needs `rr`, and `rr` comes from
Snell. Each step is a root found numerically, not a substitution.

## `within:`

`within:` is the branch a quantity physically lives on — a refracted angle is
between zero and a right angle, a reflectance is a fraction. It matters: `sin`
is periodic, so without a declared domain a solver is free to return any of the
infinitely many roots of Snell's law, and Newton's method will happily hand you
one several turns away.

It is also the only thing the solver is told. Nothing supplies a starting
point: Newton begins at the middle of the declared branch, and a root found
outside it is discarded in favour of bisecting inside it.

## Chapters

A law is a module, not a class, because a law is not a kind of another law.

| | | |
|---|---|---|
| 1.1 | `Reflection` | one equation; what it means for `==` to build rather than compare |
| 1.2 | `Refraction` | Snell, declared domains, total internal reflection as a condition |
| 1.3 | `Reflectance` | Fresnel: three equations, and the solver reaching back through Snell |

Two well-known numbers fall out of Fresnel rather than being stated anywhere:

- reflection reaches 1 exactly at the critical angle, which is what the *total*
  in total internal reflection means
- the p-polarised share reaches 0 at Brewster's angle, which is why polarised
  sunglasses cut glare off water

## The demo

**[Open it](https://fazzle.dev/phryzby/)** — one page per chapter: file tree on
the left, the law in the middle, the demo on the right, and an irb under the
code running against the same VM.

```
>> surface.solve(:rr).in_degrees
=> 19.471220634507485
>> Physics::Scenario[Refraction].new(mu1: 1.5, mu2: 1.0, rr: 90.deg).solve(:i).in_degrees
=> 41.81031489575402
```

Each page downloads CRuby compiled to WebAssembly (about 30 MB, cached across
pages) and `fetch`es the `.rb` files out of this repository, so the page runs
the same bytes the tests run. Edit a law in the page and run it again; delete a
`within:` domain and watch the solver wander off the physical branch.

## Running it

```
ruby test/physics_test.rb               #  8 runs,  17 assertions
ruby test/physics/law_test.rb           #  3 runs,   4 assertions
ruby test/physics/quantities_test.rb    #  7 runs,  10 assertions
ruby test/physics/solver_test.rb        #  8 runs,   8 assertions
ruby test/pythagoras_test.rb            #  8 runs,  10 assertions
ruby test/light/reflection_test.rb      #  9 runs,  10 assertions
ruby test/light/refraction_test.rb      # 15 runs, 107 assertions
ruby test/light/reflectance_test.rb     # 11 runs, 195 assertions
```

No gems, no build step, and no comments — the prose is on the pages. Ruby 3.4.

## Layout

```
lib/physics.rb         requires the eight parts below
lib/physics/
  expression.rb        Expr, Const, Var, BinOp, Fn — every operator returns a node
  equation.rb          Equation and Comparison: what a declaration block returns
  scope.rb             the object a declaration block runs against
  quantities.rb        declaring a quantity, and borrowing one with `uses`
  law.rb               Declarations, and Law — a module a scenario absorbs
  solver.rb            Newton, bisection, and which one to believe
  scenario.rb          composing laws, choosing an equation, solving what it needs
  degrees.rb           Numeric#deg and #in_degrees
lib/light/optics.rb    every optical quantity, declared once
lib/light/*.rb         one law per file, and nothing else
test/                  mirrors lib/
assets/phryzby.js      the tree, highlighting, the editor, booting CRuby — no build step
assets/phryzby.css
index.html             contents
light/*.html           one page per chapter
```
