require_relative "reflectance"

module TotalInternalReflection
  extend Physics::Law

  called "Total internal reflection"
  about "a law that only sometimes holds"
  describes "Chapter 1.4 ran out of answers past the critical angle: every Fresnel equation needs a refracted angle and there is not one. This chapter states what happens instead — <code>r == 1</code> — and states it <em>conditionally</em>, so the solver reaches for it only in the regime where it is true. One equation, one <code>when:</code>, and the word <em>total</em> stops being a claim in prose."
  include Reflectance

  equation(:everything_reflects, when: :no_refracted_ray) { r == 1 }
end
