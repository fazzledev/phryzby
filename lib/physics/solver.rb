module Physics
  module Solver
    SOMEWHERE = 1.0

    module_function

    # A branch is declared when an equation has more than one root and only
    # one of them is real. Where none is declared there is nothing to choose
    # between, so Newton is asked and believed — and it may answer anywhere,
    # rather than inside a range nobody asked for.
    def root(residual, within: nil, guess: nil)
      return newton(residual, guess || SOMEWHERE) unless within

      found = newton(residual, guess || midpoint(within))
      found = nil unless found && within.cover?(found)
      found || bisect(residual, within)
    end

    def midpoint(range) = (range.begin + range.end) / 2.0

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

    SCAN = 1000

    def bisect(residual, range, steps: 200)
      lo, hi = range.begin, range.end
      scan = along(residual, lo, hi).each_cons(2).find do |a, b|
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

    # An end of the range where the residual blows up — a sine going to zero,
    # say — is approached rather than stood on, so that a root just inside it
    # is still inside the first step rather than beyond the edge of the scan.
    def along(residual, lo, hi)
      step = (hi - lo) / SCAN
      walked = lo.step(by: step, to: hi).to_a
      walked[0] = lo + step / SCAN unless finite(residual, lo)
      walked[-1] = hi - step / SCAN unless finite(residual, hi)

      walked
    end

    def finite(residual, x)
      value = residual.call(x)
      value.finite? ? value : nil
    rescue Math::DomainError
      nil
    end
  end
end
