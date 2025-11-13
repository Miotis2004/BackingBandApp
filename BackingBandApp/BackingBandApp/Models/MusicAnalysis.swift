//
//  MusicAnalysis.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

struct Chord: Identifiable, Codable {
    let id = UUID()
    let root: String        // "C", "F#", etc.
    let quality: ChordQuality
    let startTime: Double
    let duration: Double
    
    var displayName: String {
        "\(root)\(quality.symbol)"
    }
}

enum ChordQuality: String, Codable {
    case major = ""
    case minor = "m"
    case dominant7 = "7"
    case major7 = "maj7"
    case minor7 = "m7"
    case diminished = "dim"
    case augmented = "aug"
    
    var symbol: String { rawValue }
}

struct SongSection: Identifiable, Codable {
    let id = UUID()
    let type: SectionType
    let startTime: Double
    let endTime: Double
    
    var duration: Double {
        endTime - startTime
    }
}

enum SectionType: String, Codable, CaseIterable {
    case intro
    case verse
    case chorus
    case bridge
    case solo
    case outro
    case unknown
}

struct MusicAnalysis: Codable {
    let tempo: Double               // BPM
    let timeSignature: TimeSignature
    let key: String                 // "C major", "A minor"
    let chords: [Chord]
    let sections: [SongSection]
    let totalDuration: Double       // In seconds
    
    init(tempo: Double = 120,
         timeSignature: TimeSignature = TimeSignature(upper: 4, lower: 4),
         key: String = "C major",
         chords: [Chord] = [],
         sections: [SongSection] = [],
         totalDuration: Double = 0) {
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.key = key
        self.chords = chords
        self.sections = sections
        self.totalDuration = totalDuration
    }
}

struct TimeSignature: Codable {
    let upper: Int  // 4 in 4/4
    let lower: Int  // 4 in 4/4
    
    var displayName: String {
        "\(upper)/\(lower)"
    }
}

enum Genre: String, CaseIterable, Codable {
    case rock
    case pop
    case jazz
    case blues
    case funk
    case country
    
    var displayName: String {
        rawValue.capitalized
    }
}
