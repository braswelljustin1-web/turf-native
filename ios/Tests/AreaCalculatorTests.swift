import XCTest
#if SWIFT_PACKAGE
@testable import TurfCore
#else
@testable import TurfOrnamentalPro
#endif

final class AreaCalculatorTests: XCTestCase {
    func testN01() throws {
        let input = AreaInput(area: "10000", areaUnit: .squareFeet, rate: "0.5", productUnit: .fluidOunces, basis: "1000", basisUnit: .squareFeet)
        XCTAssertEqual(try AreaCalculator.amount(input), 5)
    }
    func testEquivalentAreaUnits() throws {
        let acre = AreaInput(area: "1", areaUnit: .acres, rate: "1", productUnit: .grams, basis: "1", basisUnit: .acres)
        let feet = AreaInput(area: "43560", areaUnit: .squareFeet, rate: "1", productUnit: .grams, basis: "1", basisUnit: .acres)
        XCTAssertEqual(try AreaCalculator.amount(acre), try AreaCalculator.amount(feet))
    }
    func testInvalidNumbers() {
        for value in ["0", "-1", "NaN", "Infinity", "1,000", "1e3", "1000000001"] {
            XCTAssertThrowsError(try AreaCalculator.parse(value))
        }
    }
    func testMassAndVolumeCannotShareAmbiguousUnit() {
        XCTAssertNil(ProductUnit(rawValue: "oz"))
        XCTAssertNotEqual(ProductUnit.massOunces, ProductUnit.fluidOunces)
    }
}
