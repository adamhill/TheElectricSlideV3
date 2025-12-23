// File: TheElectricSlideTests/PDF/PDFExportConfigurationTests.swift

import Testing
@testable import TheElectricSlide
import SlideRuleCoreV3

struct PDFExportConfigurationTests {
    
    @Test func testFixedPageDimensions() {
        let slideRule = TestScaleFactory.createEmptySlideRule()
        let config = PDFExportConfiguration(
            slideRule: slideRule,
            slideRuleName: "Test"
        )
        
        // 11" x 17" in points
        #expect(config.pageWidth == 792.0)
        #expect(config.pageHeight == 1224.0)
    }
    
    @Test func testCenteringOffsets() {
        let slideRule = TestScaleFactory.createEmptySlideRule()
        let config = PDFExportConfiguration(
            size: .full, // 708 points
            slideRule: slideRule,
            slideRuleName: "Test"
        )
        
        // (792 - 708) / 2 = 42
        #expect(config.contentOffsetX == 42.0)
    }
    
    @Test func testTotalRuleHeight() {
        let dScale = TestScaleFactory.createSimpleScale(name: "D", length: 708)
        // Simple scale height is usually 40 in test factory (or whatever we specify)
        
        let slideRule = SlideRule(
            frontTopStator: Stator(name: "Top", scales: [dScale], heightInPoints: 40),
            frontSlide: Slide(name: "Slide", scales: [dScale], heightInPoints: 40),
            frontBottomStator: Stator(name: "Bottom", scales: [dScale], heightInPoints: 40),
            totalLengthInPoints: 708
        )
        
        let config = PDFExportConfiguration(
            slideRule: slideRule,
            slideRuleName: "Test"
        )
        
        // Each component has 1 scale of height 40.
        // totalHeight(for: component) = 40 + (1-1)*4 = 40.
        // totalRuleHeight = 40 + 40 + 40 + 8 = 128.
        #expect(config.totalRuleHeight(for: .frontOnly) == 128.0)
    }
}
