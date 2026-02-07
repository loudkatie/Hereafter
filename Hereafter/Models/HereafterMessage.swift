//
//  HereafterMessage.swift
//  Hereafter
//
//  A message planted in a place, locked to a date, waiting for future-you.
//

import Foundation
import CoreLocation

/// A single message pinned to a location and locked until a future date.
struct HereafterMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let threadID: UUID
    let parentMessageID: UUID?
    
    // Location
    let latitude: Double
    let longitude: Double
    let placeName: String?
    
    // Content
    let messageText: String          // Required, 500 char max
    let photoAssetID: String?        // CloudKit asset reference (future)
    
    // Timing
    let createdAt: Date
    let unlockDate: Date             // Date-only — no time component
    
    // Ownership
    let creatorID: String
    
    // State
    var isRead: Bool
    
    // MARK: - Computed
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isUnlocked: Bool {
        Calendar.current.startOfDay(for: unlockDate) <= Calendar.current.startOfDay(for: Date())
    }
    
    var isReply: Bool {
        parentMessageID != nil
    }
    
    /// Human-readable time since creation: "3 months ago", "1 year ago"
    var timeSincePlanted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Days until unlock, or nil if already unlocked
    var daysUntilUnlock: Int? {
        guard !isUnlocked else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let unlock = Calendar.current.startOfDay(for: unlockDate)
        return Calendar.current.dateComponents([.day], from: today, to: unlock).day
    }
    
    // MARK: - Factory
    
    /// Create a new message at the current location
    static func create(
        text: String,
        unlockDate: Date,
        coordinate: CLLocationCoordinate2D,
        placeName: String?,
        threadID: UUID? = nil,
        parentMessageID: UUID? = nil,
        creatorID: String
    ) -> HereafterMessage {
        HereafterMessage(
            id: UUID(),
            threadID: threadID ?? UUID(),
            parentMessageID: parentMessageID,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            placeName: placeName,
            messageText: String(text.prefix(500)),
            photoAssetID: nil,
            createdAt: Date(),
            unlockDate: unlockDate,
            creatorID: creatorID,
            isRead: false
        )
    }
    
    // MARK: - Equatable
    
    static func == (lhs: HereafterMessage, rhs: HereafterMessage) -> Bool {
        lhs.id == rhs.id
    }
}
