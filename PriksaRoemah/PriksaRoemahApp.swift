//
//  PriksaRoemahApp.swift
//  PriksaRoemah
//
//  Created by Marcello Evan Wijaya on 03/07/26.
//

import SwiftUI

@main
struct PriksaRoemahApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView {
                    withAnimation { hasCompletedOnboarding = true }
                }
            }
        }
    }
}
