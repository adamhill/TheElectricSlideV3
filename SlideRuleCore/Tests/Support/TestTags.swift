import Testing

/// Centralized test tags for Swift Testing suites.
/// Usage: @Test("name", .tags(.fast, .regression))
extension Tag {
    @Tag public static var fast: Self
    @Tag public static var regression: Self
    @Tag public static var flaky: Self
    @Tag public static var circular: Self
    @Tag public static var performance: Self
    @Tag public static var bScale: Self
    @Tag public static var cScale: Self
    @Tag public static var dScale: Self
    @Tag public static var ciScale: Self
    @Tag public static var diScale: Self
    @Tag public static var cfScale: Self
    @Tag public static var dfScale: Self
    @Tag public static var cifScale: Self
    @Tag public static var difScale: Self
}