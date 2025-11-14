//
//  TempoDetectionService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

class TempoDetectionService {
    
    // MARK: - Detect Tempo from MIDI Notes
    func detectTempo(from track: MIDITrack) -> Double {
        guard !track.notes.isEmpty else { return 120.0 }
        
        // Get all note onset times
        let onsetTimes = track.notes.map { $0.startTime }.sorted()
        
        guard onsetTimes.count > 2 else { return 120.0 }
        
        // Calculate inter-onset intervals (IOIs)
        var intervals: [TimeInterval] = []
        for i in 0..<(onsetTimes.count - 1) {
            let interval = onsetTimes[i + 1] - onsetTimes[i]
            // Filter out very short intervals (likely ornaments or fast notes)
            if interval > 0.1 && interval < 2.0 {
                intervals.append(interval)
            }
        }
        
        guard !intervals.isEmpty else { return 120.0 }
        
        // Find the most common interval (histogram approach)
        let bpmCandidates = intervals.map { 60.0 / $0 }
        
        // Round to nearest 5 BPM and find mode
        let roundedBPMs = bpmCandidates.map { round($0 / 5.0) * 5.0 }
        let bpm = mostCommonValue(in: roundedBPMs) ?? 120.0
        
        // Clamp to reasonable range
        return max(60.0, min(200.0, bpm))
    }
    
    // MARK: - Detect Time Signature
    func detectTimeSignature(from track: MIDITrack, tempo: Double) -> TimeSignature {
        // For now, assume 4/4
        // (Proper detection would analyze beat patterns and accent patterns)
        return TimeSignature(upper: 4, lower: 4)
    }
    
    // MARK: - Helper Methods
    private func mostCommonValue(in values: [Double]) -> Double? {
        var counts: [Double: Int] = [:]
        
        for value in values {
            counts[value, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
