import Bessel
import Numeric
import Testing

enum `Bessel Tests` {}

extension `Bessel Tests` {
    @Suite struct Values {}
    @Suite struct Zeros {}
}

private func close(_ a: Double, _ b: Double, within tolerance: Double = 1e-12) -> Bool {
    (a - b).magnitude <= tolerance * Swift.max(1, b.magnitude)
}

extension `Bessel Tests`.Values {
    @Test(arguments: [
        (UInt(0), 1.0, 0.7651976865579666), (1, 1.0, 0.4400505857449335), (2, 5.0, 0.04656511627775222),
        (0, 30.0, -0.0863679835810403), (5, 10.0, -0.2340615281867936), (10, 1.0, 2.630615123687453e-10),
        (1, 100.0, -0.07714535201411216),
    ])
    func `Known values`(order: UInt, x: Double, expected: Double) {
        #expect(close(Bessel.First<Double>(order: Cardinal(order)).value(at: x), expected))
    }

    @Test func `At zero only order zero is one`() {
        #expect(Bessel.First<Double>(order: 0).value(at: 0) == 1)
        #expect(Bessel.First<Double>(order: 3).value(at: 0) == 0)
    }

    @Test(arguments: [0.3, 2.0, 7.5, 24.0, 26.0, 80.0, 400.0])
    func `Neighbouring orders obey the recurrence`(x: Double) {
        (UInt(1)...30).forEach { n in
            let left = Bessel.First<Double>(order: Cardinal(n - 1)).value(at: x) + Bessel.First<Double>(order: Cardinal(n + 1)).value(at: x)
            let right = 2 * Double(n) / x * Bessel.First<Double>(order: Cardinal(n)).value(at: x)
            #expect((left - right).magnitude <= 1e-12 * Swift.max(1, 2 * Double(n) / x))
        }
    }

    @Test(arguments: [0.5, 3.0, 12.0, 24.5, 25.5, 60.0])
    func `The squares of all orders sum to one`(x: Double) {
        let zero = Bessel.First<Double>(order: 0).value(at: x)
        let sum = (UInt(1)...200).reduce(zero * zero) { sum, n in
            let value = Bessel.First<Double>(order: Cardinal(n)).value(at: x)
            return sum + 2 * value * value
        }
        #expect(close(sum, 1))
    }

    @Test func `A negative argument flips the sign of odd orders only`() {
        let x = 3.7
        #expect(Bessel.First<Double>(order: 3).value(at: -x) == -Bessel.First<Double>(order: 3).value(at: x))
        #expect(Bessel.First<Double>(order: 4).value(at: -x) == Bessel.First<Double>(order: 4).value(at: x))
    }

    @Test func `The slope of order zero is minus order one`() {
        for x in [0.4, 5.0, 31.0] {
            #expect(close(Bessel.First<Double>(order: 0).slope(at: x), -Bessel.First<Double>(order: 1).value(at: x)))
        }
    }

    @Test func `Not a number stays so and infinity gives zero`() {
        #expect(Bessel.First<Double>(order: 2).value(at: .nan).isNaN)
        #expect(Bessel.First<Double>(order: 2).value(at: .infinity) == 0)
    }

    @Test func `Tiny arguments and large orders stay finite`() {
        #expect(Bessel.First<Double>(order: 0).value(at: 1e-200) == 1)
        #expect(Bessel.First<Double>(order: 1).value(at: 1e-200) == 0.5e-200)
        #expect(Bessel.First<Float>(order: 3).value(at: 1e-30) == 0)
        #expect(Bessel.First<Double>(order: 5_000_000).value(at: 2) == 0)
        #expect(close(Bessel.First<Double>(order: 30).value(at: 10), 1.551096078257338e-12, within: 1e-10))
    }

    @Test func `Single precision agrees with double`() {
        #expect((Double(Bessel.First<Float>(order: 2).value(at: 5)) - 0.04656511627775222).magnitude < 1e-6)
    }
}

extension `Bessel Tests`.Zeros {
    @Test func `Known zeros`() {
        let zero = Bessel.First<Double>(order: 0).zeros(2)
        let one = Bessel.First<Double>(order: 1).zeros(2)
        #expect(close(zero[0], 2.404825557695773))
        #expect(close(zero[1], 5.520078110286311))
        #expect(close(one[0], 3.831705970207512))
        #expect(close(one[1], 7.015586669815619))
        #expect(close(Bessel.First<Double>(order: 2).zeros(1)[0], 5.135622301840683))
        #expect(close(Bessel.First<Double>(order: 5).zeros(1)[0], 8.771483815959954))
    }

    @Test func `Zeros rise, lie where the function vanishes, and none is skipped`() {
        for order: UInt in [0, 1, 7, 40, 110] {
            let function = Bessel.First<Double>(order: Cardinal(order))
            let zeros = function.zeros(40)
            #expect(zeros.count == 40)
            for (index, zero) in zeros.enumerated() {
                #expect(function.value(at: zero).magnitude < 1e-12)
                if index > 0 {
                    let gap = zero - zeros[index - 1]
                    #expect(gap > 3 && gap < (order == 0 ? Double.pi : 12))
                }
            }
            #expect(zeros[0] > Double(order))
        }
    }

    @Test func `No zeros for a count of zero`() {
        #expect(Bessel.First<Double>(order: 1).zeros(0).isEmpty)
    }
}
