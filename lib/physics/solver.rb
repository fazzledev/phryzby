module Physics
  module Solver
    DEFAULT_RANGE = -10.0..10.0

    module_function

    def root(residual, guess:, within: DEFAULT_RANGE)
      found = newton(residual, guess)
      found = nil unless found && within.cover?(found)
      found || bisect(residual, within)
    end

    def newton(residual, guess, steps: 50, tolerance: 1e-12)
      x = guess
      steps.times do
        fx = residual.call(x)
        return x if fx.abs < tolerance

        slope = (residual.call(x + 1e-7) - fx) / 1e-7
        return nil if slope.abs < 1e-14

        x -= fx / slope
        return nil unless x.finite?
      end
      residual.call(x).abs < 1e-6 ? x : nil
    rescue Math::DomainError
      nil
    end

    def bisect(residual, range, steps: 200)
      lo, hi = range.begin, range.end
      scan = lo.step(by: (hi - lo) / 1000.0, to: hi).each_cons(2).find do |a, b|
        fa = finite(residual, a)
        fb = finite(residual, b)
        fa && fb && fa * fb <= 0
      end
      return nil unless scan

      lo, hi = scan
      steps.times do
        mid = (lo + hi) / 2.0
        break if (hi - lo).abs < 1e-12

        finite(residual, lo) * finite(residual, mid) <= 0 ? hi = mid : lo = mid
      end
      (lo + hi) / 2.0
    end

    def finite(residual, x)
      value = residual.call(x)
      value.finite? ? value : nil
    rescue Math::DomainError
      nil
    end
  end
end
