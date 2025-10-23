import Testing
@testable import SlideRuleCoreV3

@Test func greetTest() async throws {
    #expect (greet(name: "World") == "Hello, World!")
}
