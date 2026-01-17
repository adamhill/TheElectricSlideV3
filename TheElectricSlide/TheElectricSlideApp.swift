//  TheElectricSlideApp.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SwiftData

@main
struct TheElectricSlideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CurrentSlideRule.self,
            SlideRuleDefinitionModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Initialization
    
    /// Initialize the app and perform pre-view cleanup tasks
    init() {
        // NOTE: Uncomment the line below to re-enable cleanup of renamed/legacy slide rules
        // from the database during app startup. This is useful when slide rules have been
        // renamed in SlideRuleLibrary and the old entries need to be purged from users'
        // databases to prevent duplicate entries in the rule picker.
        //
        // cleanupRenamedRules()
    }
    
    // MARK: - Database Maintenance
    
    /// Delete rules that have been renamed in the library.
    /// Runs before any views are created to prevent stale data in @Query.
    ///
    /// Usage: Uncomment the call in init() when you need to clean up old/renamed rules.
    /// After users have updated, the call can be commented out again to avoid unnecessary
    /// database queries on every app launch.
    ///
    /// - Important: Add rule names to `renamedRuleNames` array before enabling.
    /*
    private func cleanupRenamedRules() {
        let context = sharedModelContainer.mainContext
        
        // Rules that have been renamed and should be deleted
        let renamedRuleNames = [
            "Pickett N-16 ES (Annotation Test)",  // Renamed to "Configuration Playground"
            "Pickett N-16 ES (API Demo)"          // Also renamed to "Configuration Playground"
        ]
        
        for oldName in renamedRuleNames {
            let predicate = #Predicate<SlideRuleDefinitionModel> { rule in
                rule.name == oldName
            }
            let descriptor = FetchDescriptor<SlideRuleDefinitionModel>(predicate: predicate)
            
            do {
                let matchingRules = try context.fetch(descriptor)
                for rule in matchingRules {
                    print("  🗑️ [App Init] Deleting renamed rule: \(oldName)")
                    context.delete(rule)
                }
            } catch {
                print("  ⚠️ [App Init] Failed to fetch/delete rule '\(oldName)': \(error)")
            }
        }
        
        // Save if we made changes
        if context.hasChanges {
            do {
                try context.save()
                print("  ✅ [App Init] Cleanup complete")
            } catch {
                print("  ❌ [App Init] Failed to save cleanup: \(error)")
            }
        }
    }
    */

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
