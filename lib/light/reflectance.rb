require_relative "refraction"

module Reflectance
  extend Physics::Law

  include Refraction

  quantity :reflectance_s_polarised, variable: :r_s
  quantity :reflectance_p_polarised, variable: :r_p
  quantity :reflectance,             variable: :r

  equation(:s_polarised) do
    r_s == ((mu_1 * cos(i) - mu_2 * cos(r_r)) / (mu_1 * cos(i) + mu_2 * cos(r_r))) ** 2
  end

  equation(:p_polarised) do
    r_p == ((mu_1 * cos(r_r) - mu_2 * cos(i)) / (mu_1 * cos(r_r) + mu_2 * cos(i))) ** 2
  end

  equation(:unpolarised) { r == (r_s + r_p) / 2 }
end
