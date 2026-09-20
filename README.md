# phryzby

Physics written as Ruby, and still executable.

A law should read the way it is written on a blackboard. So inside an `equation`
block the variables are not numbers — they are expression nodes. `==` on them
builds an equation rather than answering true or false, and the solver finds a
root of `left - right` afterwards.

```ruby
class Refraction < Reflection
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: 1.0..4.0
  variable :refractive_index_of_second_medium, alias: :mu2, within: 1.0..4.0

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end
```

Because the law is stored rather than compiled into a formula, one declaration
solves in any direction. Give it two angles and it names the material:

```ruby
ray = Refraction.new(i: 45.deg, rr: 28.9.deg, mu1: 1.0)
ray.solve(:mu2, guess: 1.2).round(2)   # => 1.46, which is silica glass

ray = Refraction.new(i: 45.deg, mu1: 1.0, mu2: 1.5)
ray.solve(:rr, guess: 0.4).in_degrees  # => 28.13
```

`within:` is the branch a quantity physically lives on — a refracted angle is
between zero and a right angle, a reflectance is a fraction. It matters: `sin`
is periodic, so without a declared domain a solver is free to return any of the
infinitely many roots of Snell's law, and Newton's method will happily hand you
one several turns away.

## Chapters

Each law inherits the one before it, so each file states only what is new and
each page's code is a little more than the last.

| | | |
|---|---|---|
| 1.1 | `Reflection` | one equation; what it means for `==` to build rather than compare |
| 1.2 | `Refraction < Reflection` | Snell, declared domains, total internal reflection as a condition |
| 1.3 | `Reflectance < Refraction` | Fresnel: three equations, and the solver choosing between them |

By the third, one object holds the whole interface: ask it for the refracted
angle and it uses Snell, then ask it for a share and it uses that answer.
Nothing tells it which equation to reach for.

Two well-known numbers fall out of Fresnel rather than being stated anywhere:

- reflection reaches 1 exactly at the critical angle, which is what the *total*
  in total internal reflection means
- the p-polarised share reaches 0 at Brewster's angle, which is why polarised
  sunglasses cut glare off water

## The demo

**[Open it](https://fazzle.dev/phryzby/)** — one page per chapter. Each
downloads CRuby compiled to WebAssembly (about 30 MB, cached across pages) and
`fetch`es the `.rb` files out of this repository, so the page runs the same
bytes the tests run. Edit a law in the page and run it again; delete a `within:`
domain and watch the solver wander off the physical branch.

## Running it

```
ruby test/physics_dsl_test.rb           #  8 runs,  17 assertions
ruby test/light/reflection_test.rb      #  7 runs,   7 assertions
ruby test/light/refraction_test.rb      # 14 runs, 106 assertions
ruby test/light/reflectance_test.rb     #  9 runs, 189 assertions
```

No gems. Ruby 3.4.

## Layout

```
lib/physics_dsl.rb     the expression tree, the declaration scope, the solver
lib/light/*.rb         the laws, each inheriting the last
test/                  mirrors lib/
assets/phryzby.js      highlighting, the editor, and booting CRuby — no build step
assets/phryzby.css
index.html             contents
light/*.html           one page per chapter
```
