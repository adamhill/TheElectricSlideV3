//
//  CursorValueFormattingTests.swift
//  TheElectricSlideTests
//
//  Tests for cursor value formatting with precision improvements
//  following physical slide rule reading conventions.
//

import Foundation
import Testing
import SlideRuleCoreV3

// MARK: - Test Helper

/// Replicates the cursor value formatting logic for testing purposes.
/// This mirrors the implementation in CursorReadings.swift:formatValueForCursor
struct CursorValueFormatter {
    
    /// Format value for cursor reading display using specified decimal places
    /// Strips trailing zeros and pads integer portion for decimal point alignment
    /// - Parameters:
    ///   - value: The value to format
    ///   - decimalPlaces: Number of decimal places (from scale definition)
    /// - Returns: Formatted string for display with padded integer portion for alignment
    static func format(value: Double, decimalPlaces: Int) -> String {
        // Handle non-finite values
        guard value.isFinite else {
            return "  —"  // Em dash with padding for undefined/infinite
        }
        
        // Use configurable minimum decimal places from precision constants
        let effectiveDecimalPlaces = max(CursorValuePrecision.defaultCursorDecimalPlaces, decimalPlaces)
        var formatted = String(format: "%.\(effectiveDecimalPlaces)f", value)
        
        // Strip trailing zeros after decimal point
        // "2.000" → "2", "2.500" → "2.5", "2.340" → "2.34"
        while formatted.contains(".") && (formatted.hasSuffix("0") || formatted.hasSuffix(".")) {
            if formatted.hasSuffix(".") {
                formatted.removeLast()
                break
            }
            formatted.removeLast()
        }
        
        // Pad integer part for alignment
        if let decimalIndex = formatted.firstIndex(of: ".") {
            let integerPart = String(formatted[..<decimalIndex])
            let decimalPart = String(formatted[decimalIndex...])
            
            // Pad integer part to 2 characters for alignment
            let paddedInteger = String(repeating: " ", count: max(0, 2 - integerPart.count)) + integerPart
            return paddedInteger + decimalPart
        } else {
            // No decimal point (value like "2" or "123" after stripping)
            let paddedInteger = String(repeating: " ", count: max(0, 2 - formatted.count)) + formatted
            return paddedInteger
        }
    }
}

// MARK: - Default Decimal Places Constant Tests

struct CursorDefaultDecimalPlacesTests {
    
    @Test("Default cursor decimal places constant exists and equals 2")
    func defaultConstantExists() {
        #expect(CursorValuePrecision.defaultCursorDecimalPlaces == 2)
    }
    
    @Test("Minimum decimal places is enforced when scale provides fewer")
    func minimumDecimalPlacesEnforced() {
        // When scale provides 1 decimal place, default (2) should be used
        let result1 = CursorValueFormatter.format(value: 2.5, decimalPlaces: 1)
        // Should show at least 2 decimal places worth of precision potential
        // but trailing zeros stripped, so "2.5" remains
        #expect(result1 == " 2.5")
        
        // When scale provides 0 decimal places, default (2) should be used
        let result0 = CursorValueFormatter.format(value: 2.0, decimalPlaces: 0)
        // Should strip to "2" since trailing zeros removed
        #expect(result0 == " 2")
    }
    
    @Test("Higher decimal places from scale are honored")
    func higherDecimalPlacesHonored() {
        // When scale provides 4 decimal places, that should be used
        let result = CursorValueFormatter.format(value: 3.1416, decimalPlaces: 4)
        #expect(result == " 3.1416")
        
        // Even with more precision in the value
        let resultPrecise = CursorValueFormatter.format(value: 3.14159, decimalPlaces: 5)
        #expect(resultPrecise == " 3.14159")
    }
}

// MARK: - Trailing Zero Stripping Tests

struct CursorTrailingZeroStrippingTests {
    
    @Test("Trailing zeros are stripped from exact values")
    func exactValuesStripped() {
        // "2.000" → " 2"
        let result = CursorValueFormatter.format(value: 2.0, decimalPlaces: 3)
        #expect(result == " 2")
    }
    
    @Test("Half values preserve significant decimal")
    func halfValuesPreserveDecimal() {
        // "2.500" → " 2.5"
        let result = CursorValueFormatter.format(value: 2.5, decimalPlaces: 3)
        #expect(result == " 2.5")
    }
    
    @Test("Trailing zeros after significant decimals are stripped")
    func trailingZerosAfterSignificantStripped() {
        // "1.340" → " 1.34"
        let result = CursorValueFormatter.format(value: 1.34, decimalPlaces: 3)
        #expect(result == " 1.34")
    }
    
    @Test("Non-zero ending decimals are preserved")
    func nonZeroEndingPreserved() {
        // "3.142" → " 3.142"
        let result = CursorValueFormatter.format(value: 3.142, decimalPlaces: 3)
        #expect(result == " 3.142")
        
        // More precision
        let resultPi = CursorValueFormatter.format(value: 3.14159, decimalPlaces: 5)
        #expect(resultPi == " 3.14159")
    }
    
    @Test("Zero value is stripped to single digit")
    func zeroValueStripped() {
        // "0.000" → " 0"
        let result = CursorValueFormatter.format(value: 0.0, decimalPlaces: 3)
        #expect(result == " 0")
    }
    
    @Test("Small decimals with trailing zeros stripped correctly")
    func smallDecimalsStripped() {
        // "0.010" → " 0.01"
        let result = CursorValueFormatter.format(value: 0.01, decimalPlaces: 3)
        #expect(result == " 0.01")
        
        // "0.100" → " 0.1"
        let resultTenth = CursorValueFormatter.format(value: 0.1, decimalPlaces: 3)
        #expect(resultTenth == " 0.1")
    }
}

// MARK: - Padding Consistency Tests

struct CursorPaddingConsistencyTests {
    
    @Test("Values less than 10 have leading space")
    func valuesLessThan10HaveLeadingSpace() {
        // " 2"
        #expect(CursorValueFormatter.format(value: 2.0, decimalPlaces: 2).hasPrefix(" 2"))
        
        // " 2.5"
        #expect(CursorValueFormatter.format(value: 2.5, decimalPlaces: 2).hasPrefix(" 2"))
        
        // " 3.142"
        #expect(CursorValueFormatter.format(value: 3.142, decimalPlaces: 3).hasPrefix(" 3"))
        
        // " 9.99"
        #expect(CursorValueFormatter.format(value: 9.99, decimalPlaces: 2).hasPrefix(" 9"))
    }
    
    @Test("Values from 10 to 99 have no leading space")
    func valuesTensHaveNoLeadingSpace() {
        // "12"
        let result12 = CursorValueFormatter.format(value: 12.0, decimalPlaces: 2)
        #expect(!result12.hasPrefix(" "))
        #expect(result12 == "12")
        
        // "12.5"
        let result12_5 = CursorValueFormatter.format(value: 12.5, decimalPlaces: 2)
        #expect(!result12_5.hasPrefix(" "))
        #expect(result12_5 == "12.5")
        
        // "99.9"
        let result99 = CursorValueFormatter.format(value: 99.9, decimalPlaces: 2)
        #expect(!result99.hasPrefix(" "))
    }
    
    @Test("Values 100 and above have no padding")
    func valuesHundredsHaveNoPadding() {
        // "123"
        let result123 = CursorValueFormatter.format(value: 123.0, decimalPlaces: 2)
        #expect(result123 == "123")
        
        // "123.5"
        let result123_5 = CursorValueFormatter.format(value: 123.5, decimalPlaces: 2)
        #expect(result123_5 == "123.5")
        
        // "999.99"
        let result999 = CursorValueFormatter.format(value: 999.99, decimalPlaces: 2)
        #expect(result999 == "999.99")
    }
    
    @Test("Decimal values less than 1 have leading space")
    func decimalValuesHaveLeadingSpace() {
        // " 0.5"
        let result = CursorValueFormatter.format(value: 0.5, decimalPlaces: 2)
        #expect(result == " 0.5")
        
        // " 0.123"
        let resultSmall = CursorValueFormatter.format(value: 0.123, decimalPlaces: 3)
        #expect(resultSmall == " 0.123")
    }
}

// MARK: - Edge Case Tests

struct CursorEdgeCaseTests {
    
    @Test("Infinity displays as em dash with padding")
    func infinityDisplaysAsDash() {
        let result = CursorValueFormatter.format(value: .infinity, decimalPlaces: 3)
        #expect(result == "  —")
    }
    
    @Test("Negative infinity displays as em dash with padding")
    func negativeInfinityDisplaysAsDash() {
        let result = CursorValueFormatter.format(value: -.infinity, decimalPlaces: 3)
        #expect(result == "  —")
    }
    
    @Test("NaN displays as em dash with padding")
    func nanDisplaysAsDash() {
        let result = CursorValueFormatter.format(value: .nan, decimalPlaces: 3)
        #expect(result == "  —")
    }
    
    @Test("Large values format correctly")
    func largeValuesFormat() {
        // 999.999 with 3 decimal places
        let result999 = CursorValueFormatter.format(value: 999.999, decimalPlaces: 3)
        #expect(result999 == "999.999")
        
        // Exact 1000
        let result1000 = CursorValueFormatter.format(value: 1000.0, decimalPlaces: 2)
        #expect(result1000 == "1000")
    }
    
    @Test("Very small non-zero values format correctly")
    func verySmallValuesFormat() {
        // 0.001 with 3 decimal places
        let result = CursorValueFormatter.format(value: 0.001, decimalPlaces: 3)
        #expect(result == " 0.001")
        
        // 0.01 shows without trailing zeros
        let result01 = CursorValueFormatter.format(value: 0.01, decimalPlaces: 3)
        #expect(result01 == " 0.01")
    }
    
    @Test("Negative values format correctly")
    func negativeValuesFormat() {
        // Negative values (less common on slide rules but should work)
        let resultNeg = CursorValueFormatter.format(value: -2.5, decimalPlaces: 2)
        // -2.5 has 2 characters before decimal, so no padding needed
        #expect(resultNeg == "-2.5")
        
        let resultNegSmall = CursorValueFormatter.format(value: -0.5, decimalPlaces: 2)
        // -0.5 has 2 characters before decimal (-0), no padding
        #expect(resultNegSmall == "-0.5")
    }
    
    @Test("Rounding behavior is correct")
    func roundingBehavior() {
        // Value that would round up
        let result = CursorValueFormatter.format(value: 2.999, decimalPlaces: 2)
        // 2.999 with 2 decimal places rounds to 3.00, then strips to "3"
        #expect(result == " 3")
        
        // Value that stays as is
        let resultNoRound = CursorValueFormatter.format(value: 2.994, decimalPlaces: 2)
        // 2.994 with 2 decimal places rounds to 2.99
        #expect(resultNoRound == " 2.99")
    }
}

// MARK: - Integration Tests

struct CursorFormattingIntegrationTests {
    
    @Test("Typical slide rule values format correctly")
    func typicalSlideRuleValues() {
        // C/D scale typical values (1-10)
        #expect(CursorValueFormatter.format(value: 1.0, decimalPlaces: 2) == " 1")
        #expect(CursorValueFormatter.format(value: 2.0, decimalPlaces: 2) == " 2")
        #expect(CursorValueFormatter.format(value: 5.0, decimalPlaces: 2) == " 5")
        #expect(CursorValueFormatter.format(value: 10.0, decimalPlaces: 2) == "10")
        
        // Common calculation results
        #expect(CursorValueFormatter.format(value: 3.14, decimalPlaces: 2) == " 3.14")
        #expect(CursorValueFormatter.format(value: 2.71, decimalPlaces: 2) == " 2.71")
        #expect(CursorValueFormatter.format(value: 1.41, decimalPlaces: 2) == " 1.41")
    }
    
    @Test("K scale values format correctly")
    func kScaleValues() {
        // K scale typical values (1-1000)
        #expect(CursorValueFormatter.format(value: 1.0, decimalPlaces: 2) == " 1")
        #expect(CursorValueFormatter.format(value: 8.0, decimalPlaces: 2) == " 8")
        #expect(CursorValueFormatter.format(value: 27.0, decimalPlaces: 2) == "27")
        #expect(CursorValueFormatter.format(value: 125.0, decimalPlaces: 2) == "125")
        #expect(CursorValueFormatter.format(value: 1000.0, decimalPlaces: 2) == "1000")
    }
    
    @Test("A/B scale values format correctly")
    func abScaleValues() {
        // A/B scale typical values (1-100)
        #expect(CursorValueFormatter.format(value: 1.0, decimalPlaces: 2) == " 1")
        #expect(CursorValueFormatter.format(value: 4.0, decimalPlaces: 2) == " 4")
        #expect(CursorValueFormatter.format(value: 25.0, decimalPlaces: 2) == "25")
        #expect(CursorValueFormatter.format(value: 100.0, decimalPlaces: 2) == "100")
    }
}