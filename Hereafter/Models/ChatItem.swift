//
//  ChatItem.swift
//  Hereafter
//
//  The unified model for everything that appears in the chat thread.
//  System prompts, user messages, unlock reveals — all ChatItems.
//

import Foundation

/// Everything in the chat is a ChatItem. This is the single source of truth
/// for what appears on screen.
enum ChatItem: Identifiable {
    
    /// A message from Hereafter (the host/guide)
    case system(SystemMessage)
    
    /// A user's planted message
    case userMessage(HereafterMessage)
    
    /// A quick-reply button the user can tap
    case quickReply(QuickReply)
    
    /// A typing indicator (Hereafter is "typing")
    case typing(id: UUID = UUID())
    
    var id: String {
        switch self {
        case .system(let msg): return "sys-\(msg.id)"
        case .userMessage(let msg): return "usr-\(msg.id)"
        case .quickReply(let reply): return "qr-\(reply.id)"
        case .typing(let id): return "typing-\(id)"
        }
    }
    
    var timestamp: Date {
        switch self {
        case .system(let msg): return msg.timestamp
        case .userMessage(let msg): return msg.createdAt
        case .quickReply(let reply): return reply.timestamp
        case .typing: return Date()
        }
    }
}

// MARK: - System Message

/// A message from Hereafter itself — the warm, minimal host voice.
struct SystemMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    
    init(_ text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
    }
}

// MARK: - Quick Reply

/// A tappable response option — like "Want to leave your first one?" → [Yes] [Not yet]
struct QuickReply: Identifiable, Equatable {
    let id: UUID
    let options: [String]
    let timestamp: Date
    
    init(options: [String], timestamp: Date = Date()) {
        self.id = UUID()
        self.options = options
        self.timestamp = timestamp
    }
}
