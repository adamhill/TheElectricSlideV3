// File: TheElectricSlideTests/PDF/PDFRenderContextTests.swift

import Testing
import CoreGraphics
import Foundation
@testable import TheElectricSlide
import SlideRuleCoreV3

@MainActor
struct PDFRenderContextTests {
    
    @Test("Scale label text produces measurable dimensions") func testTextMeasurement() {
        // Create a dummy config and context
        let config = PDFExportConfiguration(
            slideRule: TestScaleFactory.createEmptySlideRule(),
            slideRuleName: "Test"
        )
        
        // We need a CGContext to create PDFRenderContext
        let data = NSMutableData()
        guard let dataConsumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: dataConsumer, mediaBox: nil, nil) else {
            Issue.record("Failed to create CGContext")
            return
        }
        
        let renderContext = PDFRenderContext(context: context, config: config)
        
        let text = "Test Text"
        let fontSize: CGFloat = 12
        let size = renderContext.measureText(text, fontSize: fontSize)
        
        #expect(size.width > 0)
        #expect(size.height > 0)
    }
    
    @Test("Drawing lines produces valid PDF data") func testLineDrawing() {
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
        renderContext.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 100))
        renderContext.endPage()
        context.closePDF()
        
        #expect(data.length > 0)
    }
    
    @Test("Registration marks render around content area") func testRegistrationMarks() {
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
        let contentRect = CGRect(x: 100, y: 100, width: 500, height: 200)
        renderContext.drawRegistrationMarks(contentRect: contentRect)
        renderContext.endPage()
        context.closePDF()
        
        #expect(data.length > 0)
    }
}
