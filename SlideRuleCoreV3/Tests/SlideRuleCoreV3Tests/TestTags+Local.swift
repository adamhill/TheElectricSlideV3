import Testing
// Local Tag definitions for this test target.
// Swift Testing defines the @Tag property wrapper to declare reusable tags.
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

//// Local fallback intentionally left empty.
//// Centralized tags are defined in Tests/Support/TestTags.swift using @Tag properties.
//// This file remains to keep path stability but defines nothing to avoid duplicate symbol issues.