extension Bessel {
    public struct First<Scalar: BinaryFloatingPoint & Trigonometry.Circular> {
        public let order: Cardinal

        public init(order: Cardinal) {
            self.order = order
        }
    }
}

extension Bessel.First: Equatable {}
extension Bessel.First: Hashable {}
extension Bessel.First: Sendable {}

extension Bessel.First {
    public func value(at x: Scalar) -> Scalar {
        guard !x.isNaN else { return .nan }
        let n = UInt(order)
        let flipped = n % 2 == 1 && x < 0
        let size = x.magnitude
        guard size.isFinite else { return 0 }
        guard size > 0 else { return n == 0 ? 1 : 0 }
        let value = size >= 25 && Scalar(n) <= size ? Self.forward(n, size) : Self.backward(n, size)
        return flipped ? -value : value
    }

    public func slope(at x: Scalar) -> Scalar {
        let above = Self(order: order + 1).value(at: x)
        guard UInt(order) > 0 else { return -above }
        return (Self(order: Cardinal(UInt(order) - 1)).value(at: x) - above) / 2
    }

    public func zeros(_ count: Cardinal) -> [Scalar] {
        let n = UInt(order)
        let even = self
        var zeros: [Scalar] = []
        zeros.reserveCapacity(count)
        var low: Scalar = n == 0 ? 1 / 2 : Scalar(n)
        var below = even.value(at: low)
        while zeros.count < Int(clamping: count) {
            var high = low + 1 / 2
            var above = even.value(at: high)
            while (below < 0) == (above < 0), above != 0 {
                low = high
                below = above
                high = low + 1 / 2
                above = even.value(at: high)
            }
            while true {
                let middle = low + (high - low) / 2
                guard middle > low, middle < high else { break }
                let between = even.value(at: middle)
                if (between < 0) == (below < 0), between != 0 {
                    low = middle
                    below = between
                } else {
                    high = middle
                }
            }
            zeros.append(high)
            low = high + 1
            below = even.value(at: low)
        }
        return zeros
    }
}

extension Bessel.First {
    static func asymptotic(_ x: Scalar) -> (zero: Scalar, one: Scalar) {
        func series(_ mu: Scalar) -> (p: Scalar, q: Scalar) {
            var p: Scalar = 1
            var q: Scalar = 0
            var term: Scalar = 1
            var last = Scalar.infinity
            var k = 1
            while k < 60 {
                let odd = Scalar(2 * k - 1)
                term *= (mu - odd * odd) / (Scalar(k) * 8 * x)
                guard term.magnitude < last, term.magnitude > Scalar.ulpOfOne / 16 else { break }
                last = term.magnitude
                switch k % 4 {
                case 1: q += term
                case 2: p -= term
                case 3: q -= term
                default: p += term
                }
                k += 1
            }
            return (p, q)
        }
        let sine = Scalar.sin(x)
        let cosine = Scalar.cos(x)
        let scale = (1 / (Scalar.pi * x)).squareRoot()
        let zero = series(0)
        let one = series(4)
        return (
            scale * (zero.p * (cosine + sine) - zero.q * (sine - cosine)),
            scale * (one.p * (sine - cosine) + one.q * (cosine + sine))
        )
    }

    static func forward(_ n: UInt, _ x: Scalar) -> Scalar {
        let start = asymptotic(x)
        guard n > 0 else { return start.zero }
        var previous = start.zero
        var current = start.one
        var k: UInt = 1
        while k < n {
            let next = 2 * Scalar(k) / x * current - previous
            previous = current
            current = next
            k += 1
        }
        return current
    }

    static func backward(_ n: UInt, _ x: Scalar) -> Scalar {
        let reach = Swift.max(Double(n), Double(x), 1)
        let top = 2 * ((Int(reach) + 22 + Int((160 * reach).squareRoot())) / 2)
        let large = Scalar.greatestFiniteMagnitude.squareRoot() / 4
        var above: Scalar = 0
        var current: Scalar = 1 / large
        var answer: Scalar = 0
        var sum: Scalar = 0
        var k = top
        while k > 0 {
            let below = 2 * Scalar(k) / x * current - above
            above = current
            current = below
            if current.magnitude > large {
                above /= large
                current /= large
                answer /= large
                sum /= large
            }
            k -= 1
            if UInt(k) == n { answer = current }
            if k % 2 == 0 { sum += k == 0 ? current : 2 * current }
        }
        return answer / sum
    }
}
