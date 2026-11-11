import Foundation
import Testing
@testable import DevPocketKit

@Test(arguments: [(3599.0, "59:59"), (7199.2, "2:00:00"), (0, "0:00"),
                  (-4, "0:00"), (0.1, "0:01"), (3600, "1:00:00"), (900, "15:00")])
func clock(interval: Double, expected: String) {
    #expect(Rules.clock(interval) == expected)
}

@Test func preferenceFormats() {
    for value in ["YES", "True", "1"] { #expect(Rules.preferenceBool(value, fallback: false)) }
    for value in ["NO", "false", "0"] { #expect(!Rules.preferenceBool(value, fallback: true)) }
    #expect(Rules.preferenceBool(NSNumber(value: true), fallback: false))
    #expect(!Rules.preferenceBool(nil, fallback: false))
    #expect(Rules.preferenceBool(nil, fallback: true))
}

@Test func gestureScrollsAreUntouched() {
    #expect(Rules.shouldReverseScroll(phase: 0, momentum: 0, continuous: 0))
    #expect(!Rules.shouldReverseScroll(phase: 1, momentum: 0, continuous: 0))
    #expect(!Rules.shouldReverseScroll(phase: 0, momentum: 2, continuous: 0))
    #expect(!Rules.shouldReverseScroll(phase: 0, momentum: 0, continuous: 1))
}
