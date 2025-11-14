//
//  ChordDetectionService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

class ChordDetectionService {
    
    // MARK: - Detect Chords
    func detectChords(from track: MIDITrack, tempo: Double) -> [Chord] {
        guard !track.notes.isEmpty else { return [] }
        
        var chords: [Chord] = []
        
        // Group notes into time windows (e.g., every beat or half-beat)
        let windowSize: TimeInterval = 60.0 / tempo  // One beat
        let totalDuration = track.notes.map { $0.startTime + $0.duration }.max() ?? 0
        
        var currentTime: TimeInterval = 0
        
        while currentTime < totalDuration {
            let windowEnd = currentTime + windowSize
            
            // Get all notes sounding in this window
            let notesInWindow = track.notes.filter { note in
                let noteEnd = note.startTime + note.duration
                return note.startTime < windowEnd && noteEnd > currentTime
            }
            
            if !notesInWindow.isEmpty {
                if let chord = identifyChord(notes: notesInWindow, startTime: currentTime, duration: windowSize) {
                    chords.append(chord)
                }
            }
            
            currentTime += windowSize
        }
        
        // Merge consecutive identical chords
        return mergeConsecutiveChords(chords)
    }
    
    // MARK: - Identify Chord from Notes
    private func identifyChord(notes: [MIDINote], startTime: TimeInterval, duration: TimeInterval) -> Chord? {
        guard !notes.isEmpty else { return nil }
        
        // Get unique pitch classes
        var pitchClasses = Set<Int>()
        for note in notes {
            pitchClasses.insert(Int(note.pitch) % 12)
        }
        
        let pitches = Array(pitchClasses).sorted()
        
        // Find root note (lowest pitch class that appears)
        guard let rootPitch = notes.map({ Int($0.pitch) }).min() else { return nil }
        let root = rootPitch % 12
        
        // Determine chord quality
        let quality = determineChordQuality(pitchClasses: pitchClasses, root: root)
        let rootName = noteNames[root]
        
        return Chord(
            root: rootName,
            quality: quality,
            startTime: startTime,
            duration: duration
        )
    }
    
    // MARK: - Determine Chord Quality
    private func determineChordQuality(pitchClasses: Set<Int>, root: Int) -> ChordQuality {
        // Normalize to root position
        let normalized = pitchClasses.map { ($0 - root + 12) % 12 }.sorted()
        
        // Single note = treat as major
        if normalized.count == 1 {
            return .major
        }
        
        // Check common chord patterns
        if normalized.contains(4) && normalized.contains(7) {
            return .major
        } else if normalized.contains(3) && normalized.contains(7) {
            return .minor
        } else if normalized.contains(4) && normalized.contains(7) && normalized.contains(10) {
            return .dominant7
        } else if normalized.contains(4) && normalized.contains(7) && normalized.contains(11) {
            return .major7
        } else if normalized.contains(3) && normalized.contains(7) && normalized.contains(10) {
            return .minor7
        } else if normalized.contains(3) && normalized.contains(6) {
            return .diminished
        } else if normalized.contains(4) && normalized.contains(8) {
            return .augmented
        } else if normalized.contains(3) {
            return .minor
        } else {
            return .major
        }
    }
    
    // MARK: - Merge Consecutive Chords
    private func mergeConsecutiveChords(_ chords: [Chord]) -> [Chord] {
        guard !chords.isEmpty else { return [] }
        
        var merged: [Chord] = []
        var current = chords[0]
        
        for i in 1..<chords.count {
            let next = chords[i]
            
            // If same chord, extend duration
            if next.root == current.root && next.quality == current.quality {
                current = Chord(
                    root: current.root,
                    quality: current.quality,
                    startTime: current.startTime,
                    duration: current.duration + next.duration
                )
            } else {
                merged.append(current)
                current = next
            }
        }
        
        merged.append(current)
        return merged
    }
    
    // MARK: - Constants
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
}
