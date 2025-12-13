import Testing
// Local Tag definitions for this test target.
// Swift Testing defines the @Tag property wrapper to declare reusable tags.
//
// TAG TAXONOMY:
// - Workflow tags: .fast, .regression, .flaky
// - Feature tags: .parsing, .formatting, .alignment, .circular, .performance
// - Scale tags: .cScale, .dScale, .ll3Scale, etc. (lowercase camelCase)
// - Rule tags: .pickettN16ES, .hemmi266, .keuffelEsser4081 (camelCase with manufacturer)
// - Historical tags: .historicalAccuracy (for tests verifying against documented specs)
extension Tag {
    // MARK: - Workflow Tags
    @Tag public static var fast: Self
    @Tag public static var regression: Self
    @Tag public static var flaky: Self
    
    // MARK: - Feature Tags
    @Tag public static var circular: Self
    @Tag public static var performance: Self
    @Tag public static var parsing: Self
    @Tag public static var formatting: Self
    @Tag public static var alignment: Self
    @Tag public static var tickGeneration: Self
    @Tag public static var labelLevels: Self
    @Tag public static var density: Self
    
    // MARK: - Scale-Specific Tags
    @Tag public static var bScale: Self
    @Tag public static var cScale: Self
    @Tag public static var dScale: Self
    @Tag public static var ciScale: Self
    @Tag public static var diScale: Self
    @Tag public static var cfScale: Self
    @Tag public static var dfScale: Self
    @Tag public static var cifScale: Self
    @Tag public static var difScale: Self
    @Tag public static var dfmScale: Self
    @Tag public static var kscale: Self
    @Tag public static var foldedScale: Self
    
    // MARK: - Historical Slide Rule Tags
    @Tag public static var pickettN16ES: Self
    @Tag public static var hemmi266: Self
    @Tag public static var keuffelEsser4081: Self
    @Tag public static var pickett803: Self
    @Tag public static var historicalAccuracy: Self
    @Tag public static var historicalExample: Self
}

//// Local fallback intentionally left empty.
//// Centralized tags are defined in Tests/Support/TestTags.swift using @Tag properties.
//// This file remains to keep path stability but defines nothing to avoid duplicate symbol issues.