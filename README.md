# phryzby

Play with physics, learn with Ruby.

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
  include Incidence

  quantity :angle_of_refraction, variable: :rr, within: Physics::A_RIGHT_ANGLE
  quantity :refractive_index_of_first_medium,  variable: :mu1
  quantity :refractive_index_of_second_medium, variable: :mu2
  quantity :relative_refractive_index,         variable: :mu21

  equation(:relative_index) { mu21 == mu2 / mu1 }
  equation(:snells_law)     { mu21 == sin(i) / sin(rr) }

  condition(:no_refracted_ray) { sin(i) / mu21 > 1 }
end
```

That is the whole file. A law is a module and holds no values; nothing composes
laws until a question is asked:

```ruby
glass = Physics::Scenario.including(Refraction)

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

Not every chapter is a law. `Incidence` states one quantity and no equation —
an arriving ray has an angle, and that is all — so it extends
`Physics::Quantities`, which knows nothing about equations and cannot be asked
for any. `Reflection` and `Refraction` are laws, extend `Physics::Law`, and
both begin `include Incidence`.

That is the same `include` that composes a law into a scenario, which is why
the scenario spells it the same way: `Physics::Scenario.including(Reflection,
Refraction)`. Anything that declares is absorbed the moment it is included, and
it makes no difference whether the thing including it is another law or the
scenario being solved.

The equation block is evaluated against those declarations and can see nothing
else, so a quantity the law never named is a `NameError` at declaration rather
than a wrong answer later.

## Asking for one thing gets you the rest

A scenario names the laws that hold where the question is being asked. It is
not told which equation to use, or in what order:

```ruby
surface = Physics::Scenario.including(Reflection, Refraction, Reflectance)
                           .new(i: 40.deg, mu1: 1.0, mu2: 1.5)

surface.solve(:r)         # => 0.0457, the reflected share
surface[:rr].in_degrees   # => 25.3740 — Snell, which nobody asked for
```

Fresnel's equations need the refracted angle, which only Snell determines. So
asking for the reflectance reaches back through five equations: the unpolarised
mean needs both polarisations, each of those needs `rr`, and `rr` comes from
Snell. Each step is a root found numerically, not a substitution.

An equation prints back the notation it was written in, not the quantities
underneath it — `snells_law.to_s` is `mu21 == (sin(i) / sin(rr))`. A
`Var` carries both names: the quantity it is looked up by, and the variable it
was typed as. Solving goes by the quantity, which is what lets two laws written
in different letters agree about the same thing.

## The law states itself

The expression tree is walked twice. The solver walks it for a root; `notation
.rb` walks it for MathML, so a chapter page shows its law typeset — generated,
not transcribed. Edit the law in the browser and the formula restates itself
along with the answer.

```ruby
Refraction.to_html
# => the quantities, what each is written as, the branch it lives on,
#    which law it came from, and every equation and condition as MathML
```

No renderer is loaded to draw it; browsers do MathML natively, which keeps
"no gems, no build step" literally true. What the module cannot produce is the
prose and the diagrams — prose has nowhere to live in a file with no comments,
and the SVG is optics rather than algebra.

## `within:`

`within:` is the branch a quantity physically lives on. Only the angles declare
one, because only they need it: `sin` is periodic, so Snell's law has
infinitely many roots and all but one of them are angles light cannot take.
Newton's method will happily hand you one several turns away.

A refractive index and a reflectance declare no domain at all. They appear
linearly in their equations, which therefore have exactly one root, and a
declared range would only be decoration — removing them moved no answer by more
than 1e-12 across 308 cases. A domain earns its place where an equation has
more than one root, and nowhere else.

It is also the only thing the solver is told. Nothing supplies a starting
point: Newton begins at the middle of the declared branch, and a root found
outside it is discarded in favour of bisecting inside it.

## Chapters

A law is a module, not a class, because a law is not a kind of another law.

| | | |
|---|---|---|
| 1.1 | `Incidence` | one quantity and no law; declaring is not solving |
| 1.2 | `Reflection` | the first equation; what it means for `==` to build rather than compare |
| 1.3 | `Refraction` | Snell, declared domains, and the critical angle as a question not a formula |
| 1.4 | `Reflectance` | Fresnel: three equations, and the solver reaching back through Snell |
| 1.5 | `TotalInternalReflection` | a law that only sometimes holds |

Brewster's angle falls out of Fresnel rather than being stated anywhere: the
p-polarised share reaches 0 at `atan(mu2 / mu1)`, which is why polarised
sunglasses cut glare off water.

## A law that only sometimes holds

Past the critical angle every Fresnel equation is stuck, because each needs a
refracted angle and Snell has none to give. What happens there is a different
law, and chapter 1.5 states it as one:

```ruby
module TotalInternalReflection
  extend Physics::Law
  include Reflectance

  equation(:everything_reflects, when: :no_refracted_ray) { r == 1 }
end
```

`when:` names a condition declared by a law underneath — refraction's statement
that Snell has no solution. The solver passes over any equation whose guard is
unsatisfied, and prefers a guarded one when both apply, because a special case
is the one that means something.

```ruby
surface = Physics::Scenario.including(Reflection, TotalInternalReflection)

surface.new(i: 41.81.deg, mu1: 1.5, mu2: 1.0).solve(:r)  # => 0.979855, Fresnel
surface.new(i: 41.82.deg, mu1: 1.5, mu2: 1.0).solve(:r)  # => 1.0, this law
```

Nothing outside the laws decides which. That matters because it used to: the
reflectance page had `[1.0, 1.0, 1.0]` written into its JavaScript, and it was
the one claim on the site not made by a law.

## The page is the law

A chapter page holds no description of itself. Its right-hand panel is two
calls: the law states itself, and the demonstration states the playground.

```ruby
showing Reflection, Refraction do
  title "Refraction"
  description "A ray crossing into another medium bends, by as much as the two media differ."

  input :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  input :mu2, INDEX, step: 0.01, at: 1.5, as: "μ₂ second"

  output :rr, in: :degrees
  output :no_refracted_ray, in: :plain, alarm: true

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i
    ray "refracted", crossing_at: :rr, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "no refracted ray", when: :no_refracted_ray
  end
end
```

Nothing is assigned. A demonstration answers to the law it is about —
`Physics.shown(Refraction)` — because that is a name the book already has, and
an invented one would mean nothing to anybody.

The sliders, the readings, the rays and their labels all come out of that.
Edit the law and the panel follows: change `{ i == rl }` to `{ i == rl * 2 }`
and the reflected ray swings to half the angle, the reading changes, and the
typeset formula redraws as `i = rl ⋅ 2`.

A chapter page shows both at once: the law on the left, `shown.rb` on the
right, the panel they produce beside them. Editing either moves the other half
of the page, which is the only reason to have the second one open.

A demonstration is never in a law file. A slider range is not physics, and a
law that carried one would stop being only a law. But it is on the page, as
`shown.rb` beside the law, because a declaration you cannot reach is only
hardcoding that has moved. Delete the reflected ray from the `draws` block and
it leaves the picture; rename it and the label changes; widen an `input` range
and the slider widens. Nothing about presentation lives in a law file, not even its own title: a law
states what it is made of, and how a reader is introduced to it belongs with
the rest of the showing.

## The demo

**[Open it](https://fazzle.dev/phryzby/)** — one page per chapter: file tree on
the left, the law in the middle, the demo on the right, and an irb under the
code running against the same VM.

```
>> surface.solve(:rr).in_degrees
=> 19.471220634507485
>> Physics::Scenario.including(Refraction).new(mu1: 1.5, mu2: 1.0, rr: 90.deg).solve(:i).in_degrees
=> 41.81031489575402
```

Each page downloads CRuby compiled to WebAssembly (about 30 MB, cached across
pages) and `fetch`es the `.rb` files out of this repository, so the page runs
the same bytes the tests run. Edit a law in the page and run it again; delete a
`within:` domain and watch the solver wander off the physical branch.

## Running it

```
ruby test/physics_test.rb                        #  8 runs,  17 assertions
ruby test/physics/law_test.rb                    #  7 runs,   8 assertions
ruby test/physics/quantities_test.rb             #  7 runs,  10 assertions
ruby test/physics/solver_test.rb                 #  8 runs,   8 assertions
ruby test/pythagoras_test.rb                     #  8 runs,  10 assertions
ruby test/light/incidence_test.rb                #  6 runs,  11 assertions
ruby test/light/reflection_test.rb               #  9 runs,  10 assertions
ruby test/light/refraction_test.rb               # 15 runs, 107 assertions
ruby test/light/reflectance_test.rb              # 11 runs, 195 assertions
ruby test/light/total_internal_reflection_test.rb #  6 runs, 105 assertions
```

No gems, no build step, and no comments — the prose is on the pages. Ruby 3.4.

## Layout

```
lib/physics.rb         requires the eight parts below
lib/physics/
  expression.rb        Expr, Const, Var, BinOp, Fn — every operator returns a node
  equation.rb          Equation and Comparison: what a declaration block returns
  scope.rb             the object a declaration block runs against
  quantities.rb        what exists: a quantity, the variable it is written as, its branch
  law.rb               what holds between them: equation, condition, and `when:`
  solver.rb            Newton, bisection, and which one to believe
  scenario.rb          composing laws, choosing an equation, solving what it needs
  angles.rb            Numeric#deg, #in_degrees, and the branch an angle lives on
  notation.rb          the same tree walked again, as MathML
  showing.rb           what can be varied, what to read, what to draw
lib/light/picture.rb   rays and media: the vocabulary optics is drawn in
lib/shown/light/*.rb   one per chapter, shown beside the law it demonstrates
lib/light/incidence.rb what every optical law includes
lib/light/*.rb         one law per file, each including the one before it
test/                  mirrors lib/
assets/phryzby.js      the tree, highlighting, the editor, booting CRuby — no build step
assets/phryzby.css
index.html             contents
light/*.html           one page per chapter, five of them
```
