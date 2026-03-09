// File: TheElectricSlideTests/PDF/PDFGeneratorTests.swift

import Testing
import CoreGraphics
import Foundation
@testable import TheElectricSlide
import SlideRuleCoreV3

@MainActor
struct PDFGeneratorTests {
    
    @Test("Full-size slide rule exports to PDF") func testFullSizeExport() throws {
        // Create a basic slide rule
        let cScale = TestScaleFactory.createSimpleScale(name: "C", length: 708)
        let dScale = TestScaleFactory.createSimpleScale(name: "D", length: 708)
        
        let slideRule = SlideRule(
            frontTopStator: Stator(name: "Top", scales: [dScale], heightInPoints: 40),
            frontSlide: Slide(name: "Slide", scales: [cScale], heightInPoints: 40),
            frontBottomStator: Stator(name: "Bottom", scales: [dScale], heightInPoints: 40),
            totalLengthInPoints: 708
        )
        
        let config = PDFExportConfiguration(
            size: .full,
            side: .frontOnly,
            slideRule: slideRule,
            slideRuleName: "Test Rule"
        )
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_export.pdf")
        
        try PDFGenerator.generate(config: config, to: fileURL)
        
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    @Test("Pocket-size slide rule exports to PDF") func testPocketSizeExport() throws {
        let cScale = TestScaleFactory.createSimpleScale(name: "C", length: 354)
        
        let slideRule = SlideRule(
            frontTopStator: Stator(name: "Top", scales: [cScale], heightInPoints: 40),
            frontSlide: Slide(name: "Slide", scales: [], heightInPoints: 40),
            frontBottomStator: Stator(name: "Bottom", scales: [], heightInPoints: 40),
            totalLengthInPoints: 354
        )
        
        let config = PDFExportConfiguration(
            size: .pocket,
            side: .frontOnly,
            slideRule: slideRule,
            slideRuleName: "Pocket Rule"
        )
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_pocket_export.pdf")
        
        try PDFGenerator.generate(config: config, to: fileURL)
        
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
}
