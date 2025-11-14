//
//  DrumPatternLibrary.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

// MARK: - Drum Kit MIDI Notes (General MIDI Standard)
enum DrumNote: UInt8 {
    case kick = 36           // Bass Drum
    case snare = 38          // Acoustic Snare
    case closedHihat = 42    // Closed Hi-Hat
    case openHihat = 46      // Open Hi-Hat
    case lowTom = 45         // Low Tom
    case midTom = 47         // Mid Tom
    case highTom = 50        // High Tom
    case crash = 49          // Crash Cymbal
    case ride = 51           // Ride Cymbal
}

// MARK: - Drum Pattern
struct DrumPattern {
    let name: String
    let beats: [DrumHit]
    let beatsPerBar: Int
    
    struct DrumHit {
        let drum: DrumNote
        let position: Double      // Position in beats (0.0 = downbeat, 0.5 = eighth note, etc.)
        let velocity: UInt8
    }
}

// MARK: - Pattern Library
class DrumPatternLibrary {
    
    // MARK: - Rock Patterns
    static let rockBasicGroove = DrumPattern(
        name: "Rock Basic",
        beats: [
            // Beat 1
            .init(drum: .kick, position: 0.0, velocity: 100),
            .init(drum: .closedHihat, position: 0.0, velocity: 90),
            .init(drum: .closedHihat, position: 0.5, velocity: 70),
            // Beat 2
            .init(drum: .snare, position: 1.0, velocity: 100),
            .init(drum: .closedHihat, position: 1.0, velocity: 90),
            .init(drum: .closedHihat, position: 1.5, velocity: 70),
            // Beat 3
            .init(drum: .kick, position: 2.0, velocity: 100),
            .init(drum: .closedHihat, position: 2.0, velocity: 90),
            .init(drum: .closedHihat, position: 2.5, velocity: 70),
            // Beat 4
            .init(drum: .snare, position: 3.0, velocity: 100),
            .init(drum: .closedHihat, position: 3.0, velocity: 90),
            .init(drum: .closedHihat, position: 3.5, velocity: 70),
        ],
        beatsPerBar: 4
    )
    
    static let rockEnergeticGroove = DrumPattern(
        name: "Rock Energetic",
        beats: [
            // More kicks and accents
            .init(drum: .kick, position: 0.0, velocity: 110),
            .init(drum: .closedHihat, position: 0.0, velocity: 100),
            .init(drum: .closedHihat, position: 0.5, velocity: 80),
            .init(drum: .kick, position: 0.75, velocity: 90),
            
            .init(drum: .snare, position: 1.0, velocity: 110),
            .init(drum: .closedHihat, position: 1.0, velocity: 100),
            .init(drum: .closedHihat, position: 1.5, velocity: 80),
            
            .init(drum: .kick, position: 2.0, velocity: 110),
            .init(drum: .closedHihat, position: 2.0, velocity: 100),
            .init(drum: .closedHihat, position: 2.5, velocity: 80),
            
            .init(drum: .snare, position: 3.0, velocity: 110),
            .init(drum: .closedHihat, position: 3.0, velocity: 100),
            .init(drum: .closedHihat, position: 3.5, velocity: 80),
            .init(drum: .kick, position: 3.75, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Pop Patterns
    static let popBasicGroove = DrumPattern(
        name: "Pop Basic",
        beats: [
            .init(drum: .kick, position: 0.0, velocity: 95),
            .init(drum: .closedHihat, position: 0.0, velocity: 85),
            .init(drum: .closedHihat, position: 0.5, velocity: 70),
            
            .init(drum: .snare, position: 1.0, velocity: 100),
            .init(drum: .closedHihat, position: 1.0, velocity: 85),
            .init(drum: .closedHihat, position: 1.5, velocity: 70),
            
            .init(drum: .kick, position: 2.0, velocity: 95),
            .init(drum: .closedHihat, position: 2.0, velocity: 85),
            .init(drum: .kick, position: 2.5, velocity: 85),
            .init(drum: .closedHihat, position: 2.5, velocity: 70),
            
            .init(drum: .snare, position: 3.0, velocity: 100),
            .init(drum: .closedHihat, position: 3.0, velocity: 85),
            .init(drum: .closedHihat, position: 3.5, velocity: 70),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Blues Patterns
    static let bluesShuffleGroove = DrumPattern(
        name: "Blues Shuffle",
        beats: [
            // Shuffle feel (swing eighths)
            .init(drum: .kick, position: 0.0, velocity: 90),
            .init(drum: .ride, position: 0.0, velocity: 80),
            .init(drum: .ride, position: 0.667, velocity: 65),
            
            .init(drum: .snare, position: 1.0, velocity: 85),
            .init(drum: .ride, position: 1.0, velocity: 80),
            .init(drum: .ride, position: 1.667, velocity: 65),
            
            .init(drum: .kick, position: 2.0, velocity: 90),
            .init(drum: .ride, position: 2.0, velocity: 80),
            .init(drum: .ride, position: 2.667, velocity: 65),
            
            .init(drum: .snare, position: 3.0, velocity: 85),
            .init(drum: .ride, position: 3.0, velocity: 80),
            .init(drum: .ride, position: 3.667, velocity: 65),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Jazz Patterns
    static let jazzSwingGroove = DrumPattern(
        name: "Jazz Swing",
        beats: [
            .init(drum: .kick, position: 0.0, velocity: 75),
            .init(drum: .ride, position: 0.0, velocity: 80),
            .init(drum: .ride, position: 0.667, velocity: 60),
            
            .init(drum: .ride, position: 1.0, velocity: 75),
            .init(drum: .ride, position: 1.667, velocity: 60),
            
            .init(drum: .kick, position: 2.0, velocity: 70),
            .init(drum: .ride, position: 2.0, velocity: 80),
            .init(drum: .ride, position: 2.667, velocity: 60),
            
            .init(drum: .snare, position: 3.0, velocity: 65),
            .init(drum: .ride, position: 3.0, velocity: 75),
            .init(drum: .ride, position: 3.667, velocity: 60),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Funk Patterns
    static let funkGroove = DrumPattern(
        name: "Funk",
        beats: [
            .init(drum: .kick, position: 0.0, velocity: 100),
            .init(drum: .closedHihat, position: 0.0, velocity: 85),
            .init(drum: .closedHihat, position: 0.25, velocity: 70),
            .init(drum: .closedHihat, position: 0.5, velocity: 75),
            .init(drum: .closedHihat, position: 0.75, velocity: 70),
            
            .init(drum: .snare, position: 1.0, velocity: 105),
            .init(drum: .closedHihat, position: 1.0, velocity: 85),
            .init(drum: .closedHihat, position: 1.25, velocity: 70),
            .init(drum: .closedHihat, position: 1.5, velocity: 75),
            .init(drum: .closedHihat, position: 1.75, velocity: 70),
            
            .init(drum: .kick, position: 2.0, velocity: 95),
            .init(drum: .closedHihat, position: 2.0, velocity: 85),
            .init(drum: .closedHihat, position: 2.25, velocity: 70),
            .init(drum: .kick, position: 2.5, velocity: 90),
            .init(drum: .closedHihat, position: 2.5, velocity: 75),
            .init(drum: .closedHihat, position: 2.75, velocity: 70),
            
            .init(drum: .snare, position: 3.0, velocity: 105),
            .init(drum: .closedHihat, position: 3.0, velocity: 85),
            .init(drum: .closedHihat, position: 3.25, velocity: 70),
            .init(drum: .closedHihat, position: 3.5, velocity: 75),
            .init(drum: .closedHihat, position: 3.75, velocity: 70),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Fill Patterns
    static let basicFill = DrumPattern(
        name: "Basic Fill",
        beats: [
            .init(drum: .highTom, position: 2.0, velocity: 90),
            .init(drum: .highTom, position: 2.5, velocity: 85),
            .init(drum: .midTom, position: 3.0, velocity: 95),
            .init(drum: .lowTom, position: 3.5, velocity: 100),
        ],
        beatsPerBar: 4
    )
    
    static let crashFill = DrumPattern(
        name: "Crash Fill",
        beats: [
            .init(drum: .snare, position: 2.5, velocity: 90),
            .init(drum: .snare, position: 2.75, velocity: 85),
            .init(drum: .highTom, position: 3.0, velocity: 95),
            .init(drum: .midTom, position: 3.25, velocity: 95),
            .init(drum: .lowTom, position: 3.5, velocity: 100),
            .init(drum: .crash, position: 0.0, velocity: 110), // Next bar
            .init(drum: .kick, position: 0.0, velocity: 100),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Get Patterns by Genre
    static func patterns(for genre: Genre) -> [DrumPattern] {
        switch genre {
        case .rock:
            return [rockBasicGroove, rockEnergeticGroove]
        case .pop:
            return [popBasicGroove]
        case .jazz:
            return [jazzSwingGroove]
        case .blues:
            return [bluesShuffleGroove]
        case .funk:
            return [funkGroove]
        case .country:
            return [rockBasicGroove] // Can add specific country patterns later
        }
    }
    
    static func fills() -> [DrumPattern] {
        return [basicFill, crashFill]
    }
}
