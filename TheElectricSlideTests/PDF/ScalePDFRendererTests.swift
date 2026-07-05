// File: TheElectricSlideTests/PDF/ScalePDFRendererTests.swift

import Testing
import CoreGraphics
import Foundation
@testable import TheElectricSlide
import SlideRuleCoreV3

@MainActor
struct ScalePDFRendererTests {
    
    @Test("Scale tick marks render in PDF output") func testTickRendering() throws {
        // Create a simple scale with known ticks
        let scale = TestScaleFactory.createSimpleScale(name: "C", length: 708)
        
        let config = PDFExportConfiguration(
            slideRule: TestScaleFactory.createEmptySlideRule(),
            slideRuleName: "Test"
        )
        
        let data = NSMutableData()
        guard let dataConsumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: dataConsumer, mediaBox: nil, nil) else {
            Issue.record("Failed to create CGContext")
            return
        }
        
        let renderContext = PDFRenderContext(context: context, config: config)
        
        renderContext.beginPage()
        try ScalePDFRenderer.render(
            scale: scale,
            at: CGPoint(x: 72, y: 72),
            width: 708,
            height: 36,
            renderContext: renderContext
        )
        renderContext.endPage()
        context.closePDF()
        
        #expect(data.length > 0)
    }
}
