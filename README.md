# phryzby

Physics written as Ruby, and still executable.

A law should read the way it is written on a blackboard. So inside an `equation`
block the variables are not numbers — they are expression nodes. `==` on them
builds an equation rather than answering true or false, and the solver finds a
root of `left - right` afterwards.

```ruby
class LightRayIncidence < Physics::Model
  RIGHT_ANGLE = 0.0..(Math::PI / 2)

  variable :angle_of_incidence,                alias: :i,   within: RIGHT_ANGLE
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :angle_of_reflection,               alias: :rl,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: 1.0..4.0
  variable :refractive_index_of_second_medium, alias: :mu2, within: 1.0..4.0

  equation(:snells_law)        { mu2 / mu1 == sin(i) / sin(rr) }
  equation(:law_of_reflection) { i == rl }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end
```

Because the law is stored rather than compiled into a formula, one declaration
solves in any direction. Give it two angles and it names the material:

```ruby
ray = LightRayIncidence.new(i: 45.deg, rr: 28.9.deg, mu1: 1.0)
ray.solve(:mu2, guess: 1.2).round(2)   # => 1.46, which is silica glass

ray = LightRayIncidence.new(i: 45.deg, mu1: 1.0, mu2: 1.5)
ray.solve(:rr, guess: 0.4).in_degrees  # => 28.13
```

`within:` is the branch a quantity physically lives on — a refracted angle is
between zero and a right angle, a reflectance is a fraction. It matters: `sin`
is periodic, so without a declared domain a solver is free to return any of the
infinitely many roots of Snell's law, and Newton's method will happily hand you
one several turns away.

## The second law

`FresnelReflectance` says how much of the light comes back rather than which way
it goes, and it consumes the first law's answer. Neither model knows about the
other; the test composes them.

Two well-known numbers fall out of it rather than being stated anywhere:

- reflection reaches 1 exactly at the critical angle, which is what the *total*
  in total internal reflection means
- the p-polarised share reaches 0 at Brewster's angle, which is why polarised
  sunglasses cut glare off water

## The demo

**[Open it](https://fazzle.dev/phryzby/)** — it downloads CRuby
compiled to WebAssembly (about 30 MB) and runs these exact files in the browser.
Edit a law in the page and run it again; break Snell and the solver reports that
it cannot find a root inside the branch the variable declares.

## Running it

```
ruby physics_dsl_test.rb            #  8 runs,  17 assertions
ruby light_ray_incidence_test.rb    # 14 runs, 104 assertions
ruby fresnel_reflectance_test.rb    #  9 runs, 189 assertions
```

No gems. Ruby 3.4.

## Files

| | |
|---|---|
| `physics_dsl.rb` | the expression tree, the declaration scope, and the solver |
| `light_ray_incidence.rb` | Snell's law, the law of reflection, total internal reflection |
| `fresnel_reflectance.rb` | how the light divides between the two |
| `index.html` | the WebAssembly demo, one file, no build step |
