//
//  HapticManager.swift
//  Hereafter
//
//  CoreHaptics for the unlock "tap." Should feel like someone
//  gently tapping your shoulder — not buzzing your pocket.
//
//  Pattern: tap · pause · tap
//

import Foundation
import CoreHaptics

class HapticManager {
    
    private var engine: CHHapticEngine?
    
    init() {
        prepareEngine()
    }
    
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Auto-restart if the engine stops
            engine?.stoppedHandler = { [weak self] _ in
                try? self?.engine?.start()
            }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("Hereafter: Haptic engine error — \(error)")
        }
    }
    
    // MARK: - Patterns
    
    /// The signature Hereafter unlock tap: gentle tap · pause · tap
    func playUnlockTap() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        do {
            // First tap — soft
            let tap1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
            
            // Second tap — slightly firmer
            let tap2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.25 // 250ms pause
            )
            
            let pattern = try CHHapticPattern(events: [tap1, tap2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Hereafter: Haptic playback error — \(error)")
        }
    }
    
    /// Subtle confirmation when a message is locked/planted
    func playPlantConfirmation() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Hereafter: Haptic playback error — \(error)")
        }
    }
}
