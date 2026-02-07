//
//  DateFormatting.swift
//  Hereafter
//
//  Human-readable date formatting. Warm, not technical.
//

import Foundation

extension Date {
    
    /// "March 3, 2027" — the unlock date display format
    var hereafterDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// "Feb 8, 2026" — shorter format for chat bubbles
    var hereafterShortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
    
    /// Strip time component — Hereafter uses date-only locks
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Tomorrow — the minimum unlock date
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!.startOfDay
    }
    
    /// One year from now — a nice default suggestion
    static var oneYearFromNow: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date())!.startOfDay
    }
}
