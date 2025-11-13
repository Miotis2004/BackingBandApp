//
//  MIDINote.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

struct MIDINote: Identifiable, Codable {
    let id = UUID()
    let pitch: UInt8        // MIDI note number (0-127)
    let velocity: UInt8     // Note velocity (0-127)
    let startTime: Double   // In seconds
    let duration: Double    // In seconds
    let channel: UInt8      // MIDI channel (0-15)
    
    init(pitch: UInt8, velocity: UInt8, startTime: Double, duration: Double, channel: UInt8 = 0) {
        self.pitch = pitch
        self.velocity = velocity
        self.startTime = startTime
        self.duration = duration
        self.channel = channel
    }
}

struct MIDITrack: Identifiable, Codable {
    let id = UUID()
    var name: String
    var notes: [MIDINote]
    var instrument: String  // For later: which AU to use
    
    init(name: String, notes: [MIDINote] = [], instrument: String = "Piano") {
        self.name = name
        self.notes = notes
        self.instrument = instrument
    }
}
