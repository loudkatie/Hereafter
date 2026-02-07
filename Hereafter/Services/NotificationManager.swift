//
//  NotificationManager.swift
//  Hereafter
//
//  Local notifications for message unlocks.
//  "Something you left at [Place] on [Date] just unlocked."
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    
    @Published var isAuthorized: Bool = false
    
    init() {
        checkAuthorization()
    }
    
    // MARK: - Permissions
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Hereafter: Notification permission error — \(error)")
            return false
        }
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule a notification for when a message unlocks at a location.
    /// In v1, this fires based on geofence entry (Phase 2).
    /// For now, we stub the notification content.
    func scheduleUnlockNotification(for message: HereafterMessage) {
        let content = UNMutableNotificationContent()
        content.title = "Hereafter"
        
        let place = message.placeName ?? "a place that matters"
        let date = message.createdAt.hereafterShortDate
        content.body = "Something you left at \(place) on \(date) just unlocked."
        
        content.sound = .default // TODO: Custom gentle chime
        content.categoryIdentifier = "UNLOCK"
        
        // In Phase 2, this will be triggered by geofence entry
        // For now, schedule based on unlock date as a date-based trigger
        let unlockComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: message.unlockDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: unlockComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "hereafter-\(message.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Hereafter: Notification scheduling error — \(error)")
            }
        }
    }
    
    /// Remove a scheduled notification (e.g., if message is deleted)
    func cancelNotification(for messageID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["hereafter-\(messageID.uuidString)"])
    }
    
    // MARK: - Notification Actions
    
    func registerCategories() {
        let readAction = UNNotificationAction(
            identifier: "READ",
            title: "Read",
            options: [.foreground]
        )
        let laterAction = UNNotificationAction(
            identifier: "LATER",
            title: "Later",
            options: []
        )
        
        let unlockCategory = UNNotificationCategory(
            identifier: "UNLOCK",
            actions: [readAction, laterAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([unlockCategory])
    }
}
