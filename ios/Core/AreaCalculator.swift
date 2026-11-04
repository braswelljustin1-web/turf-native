import Foundation

enum CalculationFailure: String, Error, LocalizedError {
    case number = "Enter positive decimal numbers using a dot, without grouping or exponents (maximum 1 billion)."
    case arithmetic = "The calculation exceeds supported precision. Check the input values."
    var errorDescription: String? { rawValue }
}

enum ProductUnit: String, Codable, CaseIterable, Identifiable {
    case grams = "g", kilograms = "kg", massOunces = "oz by weight", pounds = "lb"
    case fluidOunces = "US fl oz", milliliters = "mL", liters = "L"
    var id: String { rawValue }
}

enum AreaUnit: String, Codable, CaseIterable, Identifiable {
    case squareFeet = "sq ft", acres = "acres", squareMeters = "sq m", hectares = "hectares"
    var id: String { rawValue }
    // Exact square-meter factors avoid a rounded reciprocal conversion.
    var squareMeters: Decimal {
        switch self {
        case .squareFeet: return Decimal(string: "0.09290304")!
        case .acres: return Decimal(string: "4046.8564224")!
        case .squareMeters: return 1
        case .hectares: return 10000
        }
    }
}

struct AreaInput: Codable, Equatable {
    var area: String
    var areaUnit: AreaUnit
    var rate: String
    var productUnit: ProductUnit
    var basis: String
    var basisUnit: AreaUnit
}

enum AreaCalculator {
    static let version = "1.0.0"
    static func parse(_ text: String, zeroAllowed: Bool = false) throws -> Decimal {
        guard text.range(of: #"^[0-9]{1,10}(\.[0-9]{1,9})?$"#, options: .regularExpression) != nil,
              let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              value <= 1_000_000_000, value >= 0, zeroAllowed || value > 0 else {
            throw CalculationFailure.number
        }
        return value
    }
    static func multiply(_ lhs: Decimal, _ rhs: Decimal) throws -> Decimal {
        var a = lhs, b = rhs, result = Decimal()
        let status = NSDecimalMultiply(&result, &a, &b, .bankers)
        guard status == .noError else { throw CalculationFailure.arithmetic }
        return result
    }
    static func amount(_ input: AreaInput) throws -> Decimal {
        let area = try multiply(parse(input.area), input.areaUnit.squareMeters)
        let basis = try multiply(parse(input.basis), input.basisUnit.squareMeters)
        var numerator = try multiply(parse(input.rate, zeroAllowed: true), area)
        var denominator = basis
        var result = Decimal()
        let status = NSDecimalDivide(&result, &numerator, &denominator, .bankers)
        guard status == .noError || status == .lossOfPrecision else { throw CalculationFailure.arithmetic }
        return result
    }
    static func text(_ value: Decimal) -> String { NSDecimalNumber(decimal: value).stringValue }
}
