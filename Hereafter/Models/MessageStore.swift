//
//  MessageStore.swift
//  Hereafter
//
//  Local message persistence for v1. Simple JSON file storage.
//  Will be replaced by CloudKit in Phase 2+.
//

import Foundation
import CoreLocation

/// Local persistence for messages. Dead simple for v1.
class MessageStore: ObservableObject {
    
    @Published var messages: [HereafterMessage] = []
    
    private let fileURL: URL
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("hereafter_messages.json")
        load()
    }
    
    // MARK: - CRUD
    
    func save(message: HereafterMessage) {
        messages.append(message)
        persist()
    }
    
    func markAsRead(_ messageID: UUID) {
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].isRead = true
            persist()
        }
    }
    
    /// All messages at a given location (within ~150m radius)
    func messages(near coordinate: CLLocationCoordinate2D, radiusMeters: Double = 150) -> [HereafterMessage] {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return messages.filter { msg in
            let msgLocation = CLLocation(latitude: msg.latitude, longitude: msg.longitude)
            return target.distance(from: msgLocation) <= radiusMeters
        }
    }
    
    /// All messages that are unlocked but unread
    var unreadUnlocked: [HereafterMessage] {
        messages.filter { $0.isUnlocked && !$0.isRead }
    }
    
    /// All messages in a specific thread, ordered by creation date
    func thread(_ threadID: UUID) -> [HereafterMessage] {
        messages
            .filter { $0.threadID == threadID }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    // MARK: - Persistence
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Hereafter: Failed to save messages — \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            messages = try JSONDecoder().decode([HereafterMessage].self, from: data)
        } catch {
            print("Hereafter: Failed to load messages — \(error)")
        }
    }
}
