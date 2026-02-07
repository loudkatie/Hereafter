//
//  SettingsView.swift
//  Hereafter
//
//  Minimal settings. Permissions status + about. That's it.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(appState.firstName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Messages planted")
                        Spacer()
                        Text("\(appState.messageStore.messages.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Permissions
                Section("Permissions") {
                    HStack {
                        Text("Location")
                        Spacer()
                        permissionBadge(locationManager.hasLocationPermission)
                    }
                }
                
                // About
                Section("About") {
                    Text("Hereafter")
                        .font(.headline)
                    Text("Leave a message. Find it hereafter.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("By Loud Labs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func permissionBadge(_ granted: Bool) -> some View {
        Text(granted ? "Granted" : "Not granted")
            .font(.caption)
            .foregroundColor(granted ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (granted ? Color.green : Color.orange).opacity(0.1)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
