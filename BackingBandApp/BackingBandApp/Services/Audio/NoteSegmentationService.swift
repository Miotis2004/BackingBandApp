//
//  NoteSegmentationService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

class NoteSegmentationService {
    
    // Configuration
    private let minNoteDuration: TimeInterval = 0.05  // 50ms minimum
    private let pitchStabilityThreshold: UInt8 = 1    // MIDI notes within 1 semitone
    
    // MARK: - Segment Notes
    func segmentNotes(from pitchResults: [PitchDetectionService.PitchResult]) -> [MIDINote] {
        var notes: [MIDINote] = []
        
        guard !pitchResults.isEmpty else { return notes }
        
        var currentNote: (midiNote: UInt8, startTime: TimeInterval, pitches: [PitchDetectionService.PitchResult]) = (0, 0, [])
        var isInNote = false
        
        for result in pitchResults {
            guard let midiNote = result.midiNote else {
                // No confident pitch detected
                if isInNote {
                    // End current note
                    if let note = finalizeNote(currentNote) {
                        notes.append(note)
                    }
                    isInNote = false
                }
                continue
            }
            
            if !isInNote {
                // Start new note
                currentNote = (midiNote, result.time, [result])
                isInNote = true
            } else {
                // Check if pitch is stable (same note)
                if abs(Int(midiNote) - Int(currentNote.midiNote)) <= pitchStabilityThreshold {
                    // Continue current note
                    currentNote.pitches.append(result)
                } else {
                    // Pitch changed significantly, end current note and start new one
                    if let note = finalizeNote(currentNote) {
                        notes.append(note)
                    }
                    currentNote = (midiNote, result.time, [result])
                }
            }
        }
        
        // Finalize last note if exists
        if isInNote, let note = finalizeNote(currentNote) {
            notes.append(note)
        }
        
        return notes
    }
    
    // MARK: - Finalize Note
    private func finalizeNote(_ noteData: (midiNote: UInt8, startTime: TimeInterval, pitches: [PitchDetectionService.PitchResult])) -> MIDINote? {
        
        guard !noteData.pitches.isEmpty else { return nil }
        
        let startTime = noteData.startTime
        let endTime = noteData.pitches.last?.time ?? startTime
        let duration = endTime - startTime
        
        // Filter out very short notes (likely noise)
        guard duration >= minNoteDuration else { return nil }
        
        // Calculate average confidence
        let avgConfidence = noteData.pitches.reduce(0.0) { $0 + $1.confidence } / Float(noteData.pitches.count)
        
        // Calculate velocity based on confidence (0.3-1.0 → 40-127)
        let velocity = UInt8(40 + (avgConfidence * 87))
        
        // Use most common MIDI note in the segment
        let midiNote = mostCommonMIDI(in: noteData.pitches)
        
        return MIDINote(
            pitch: midiNote,
            velocity: velocity,
            startTime: startTime,
            duration: duration,
            channel: 0
        )
    }
    
    // MARK: - Helper Methods
    private func mostCommonMIDI(in pitches: [PitchDetectionService.PitchResult]) -> UInt8 {
        var counts: [UInt8: Int] = [:]
        
        for pitch in pitches {
            if let midi = pitch.midiNote {
                counts[midi, default: 0] += 1
            }
        }
        
        return counts.max(by: { $0.value < $1.value })?.key ?? 60  // Default to middle C
    }
}
