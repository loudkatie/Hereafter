//
//  AppState.swift
//  Hereafter
//
//  Global app state. The single source of truth for where the user is
//  in the app lifecycle.
//

import Foundation
import SwiftUI

/// The app's global state — drives what the user sees.
@MainActor
class AppState: ObservableObject {
    
    @Published var userProfile: UserProfile?
    @Published var isOnboarding: Bool = true
    @Published var currentPlaceName: String?
    
    let messageStore = MessageStore()
    
    init() {
        if let profile = UserProfile.load(), profile.hasCompletedOnboarding {
            self.userProfile = profile
            self.isOnboarding = false
        }
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding(firstName: String) {
        var profile = UserProfile.create(firstName: firstName)
        profile.hasCompletedOnboarding = true
        profile.save()
        self.userProfile = profile
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isOnboarding = false
        }
    }
    
    // MARK: - Helpers
    
    var firstName: String {
        userProfile?.firstName ?? "friend"
    }
    
    var creatorID: String {
        userProfile?.deviceID ?? "unknown"
    }
}
