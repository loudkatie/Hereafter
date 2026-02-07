//
//  UserProfile.swift
//  Hereafter
//
//  Local user profile — collected during onboarding, stored on device.
//

import Foundation

/// The user's local profile. No account creation, no server — just local state.
struct UserProfile: Codable {
    var firstName: String
    let createdAt: Date
    var hasCompletedOnboarding: Bool
    
    /// Device-bound identifier for message ownership
    var deviceID: String
    
    // MARK: - Factory
    
    static func create(firstName: String) -> UserProfile {
        UserProfile(
            firstName: firstName,
            createdAt: Date(),
            hasCompletedOnboarding: false,
            deviceID: UUID().uuidString
        )
    }
    
    // MARK: - Persistence (UserDefaults for v1 simplicity)
    
    private static let storageKey = "hereafter_user_profile"
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
    
    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
