//
//  HereafterApp.swift
//  Hereafter
//
//  Leave a message. Find it hereafter.
//

import SwiftUI

@main
struct HereafterApp: App {
    
    @StateObject private var appState = AppState()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isOnboarding {
                    OnboardingChatView()
                } else {
                    ChatView()
                }
            }
            .environmentObject(appState)
            .environmentObject(locationManager)
        }
    }
}
