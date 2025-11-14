//
//  BassPatternLibrary.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

// MARK: - Bass Pattern
struct BassPattern {
    let name: String
    let notes: [BassNote]
    let beatsPerBar: Int
    
    struct BassNote {
        let position: Double      // Position in beats (0.0 = downbeat)
        let rootOffset: Int       // Interval from chord root (0 = root, 7 = fifth, etc.)
        let octaveOffset: Int     // Octave adjustment (-1 = down, 0 = same, 1 = up)
        let duration: Double      // Duration in beats
        let velocity: UInt8
    }
}

// MARK: - Pattern Library
class BassPatternLibrary {
    
    // MARK: - Rock Patterns
    static let rockBasic = BassPattern(
        name: "Rock Basic",
        notes: [
            // Root on 1 and 3
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.5, velocity: 100),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.5, velocity: 95),
        ],
        beatsPerBar: 4
    )
    
    static let rockDriving = BassPattern(
        name: "Rock Driving",
        notes: [
            // Eighth note pattern
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 105),
            .init(position: 0.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
            .init(position: 1.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 95),
            .init(position: 1.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 100),
            .init(position: 2.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
            .init(position: 3.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 95),
            .init(position: 3.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    static let rockWithFifth = BassPattern(
        name: "Rock with Fifth",
        notes: [
            // Root and fifth alternating
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.5, velocity: 100),
            .init(position: 1.0, rootOffset: 7, octaveOffset: 0, duration: 0.5, velocity: 90), // Fifth
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.5, velocity: 100),
            .init(position: 3.0, rootOffset: 7, octaveOffset: 0, duration: 0.5, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Pop Patterns
    static let popGroove = BassPattern(
        name: "Pop Groove",
        notes: [
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 95),
            .init(position: 1.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 95),
            .init(position: 2.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 85),
            .init(position: 3.0, rootOffset: 7, octaveOffset: 0, duration: 0.4, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    static let popSyncopated = BassPattern(
        name: "Pop Syncopated",
        notes: [
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 100),
            .init(position: 0.75, rootOffset: 0, octaveOffset: 0, duration: 0.25, velocity: 80),
            .init(position: 1.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 90),
            .init(position: 2.5, rootOffset: 0, octaveOffset: 0, duration: 0.4, velocity: 95),
            .init(position: 3.25, rootOffset: 7, octaveOffset: 0, duration: 0.25, velocity: 85),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Blues Patterns
    static let bluesWalking = BassPattern(
        name: "Blues Walking",
        notes: [
            // Walking bass line
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.9, velocity: 90),
            .init(position: 1.0, rootOffset: 3, octaveOffset: 0, duration: 0.9, velocity: 85), // Minor third
            .init(position: 2.0, rootOffset: 5, octaveOffset: 0, duration: 0.9, velocity: 85), // Fourth
            .init(position: 3.0, rootOffset: 7, octaveOffset: 0, duration: 0.9, velocity: 90), // Fifth
        ],
        beatsPerBar: 4
    )
    
    static let bluesShuffleRoot = BassPattern(
        name: "Blues Shuffle",
        notes: [
            // Shuffle feel
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.6, velocity: 95),
            .init(position: 0.667, rootOffset: 0, octaveOffset: 0, duration: 0.3, velocity: 80),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.6, velocity: 90),
            .init(position: 2.667, rootOffset: 7, octaveOffset: 0, duration: 0.3, velocity: 80),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Jazz Patterns
    static let jazzWalking = BassPattern(
        name: "Jazz Walking",
        notes: [
            // Classic walking bass
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.9, velocity: 85),
            .init(position: 1.0, rootOffset: 3, octaveOffset: 0, duration: 0.9, velocity: 80),
            .init(position: 2.0, rootOffset: 5, octaveOffset: 0, duration: 0.9, velocity: 80),
            .init(position: 3.0, rootOffset: 7, octaveOffset: 0, duration: 0.9, velocity: 85),
        ],
        beatsPerBar: 4
    )
    
    static let jazzSwing = BassPattern(
        name: "Jazz Swing",
        notes: [
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.6, velocity: 80),
            .init(position: 0.667, rootOffset: 7, octaveOffset: 0, duration: 0.3, velocity: 70),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.6, velocity: 80),
            .init(position: 2.667, rootOffset: 5, octaveOffset: 0, duration: 0.3, velocity: 70),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Funk Patterns
    static let funkSyncopated = BassPattern(
        name: "Funk Syncopated",
        notes: [
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 110),
            .init(position: 0.5, rootOffset: 0, octaveOffset: -1, duration: 0.2, velocity: 90),
            .init(position: 1.0, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 100),
            .init(position: 1.75, rootOffset: 7, octaveOffset: 0, duration: 0.2, velocity: 95),
            .init(position: 2.25, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 105),
            .init(position: 3.0, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 100),
            .init(position: 3.5, rootOffset: 0, octaveOffset: -1, duration: 0.2, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    static let funkGroove = BassPattern(
        name: "Funk Groove",
        notes: [
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.3, velocity: 110),
            .init(position: 0.5, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 85),
            .init(position: 1.0, rootOffset: 7, octaveOffset: 0, duration: 0.3, velocity: 100),
            .init(position: 2.0, rootOffset: 0, octaveOffset: 0, duration: 0.3, velocity: 110),
            .init(position: 2.75, rootOffset: 0, octaveOffset: 0, duration: 0.2, velocity: 90),
            .init(position: 3.5, rootOffset: 5, octaveOffset: 0, duration: 0.3, velocity: 95),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Country Patterns
    static let countryTwoFeel = BassPattern(
        name: "Country Two-Feel",
        notes: [
            // Alternating bass (typical country)
            .init(position: 0.0, rootOffset: 0, octaveOffset: 0, duration: 0.9, velocity: 95),
            .init(position: 2.0, rootOffset: 7, octaveOffset: 0, duration: 0.9, velocity: 90),
        ],
        beatsPerBar: 4
    )
    
    // MARK: - Get Patterns by Genre
    static func patterns(for genre: Genre) -> [BassPattern] {
        switch genre {
        case .rock:
            return [rockBasic, rockDriving, rockWithFifth]
        case .pop:
            return [popGroove, popSyncopated]
        case .jazz:
            return [jazzWalking, jazzSwing]
        case .blues:
            return [bluesWalking, bluesShuffleRoot]
        case .funk:
            return [funkSyncopated, funkGroove]
        case .country:
            return [countryTwoFeel, rockBasic]
        }
    }
}
