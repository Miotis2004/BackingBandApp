//
//  KeyDetectionService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation

class KeyDetectionService {
    
    // Major and minor key profiles (Krumhansl-Schmuckler)
    private let majorProfile: [Double] = [
        6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88
    ]
    
    private let minorProfile: [Double] = [
        6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17
    ]
    
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    // MARK: - Detect Key
    func detectKey(from track: MIDITrack) -> String {
        guard !track.notes.isEmpty else { return "C major" }
        
        // Count pitch class occurrences
        var pitchCounts = [Int](repeating: 0, count: 12)
        
        for note in track.notes {
            let pitchClass = Int(note.pitch) % 12
            // Weight by duration
            let weight = Int(note.duration * 10)
            pitchCounts[pitchClass] += weight
        }
        
        // Normalize
        let total = pitchCounts.reduce(0, +)
        guard total > 0 else { return "C major" }
        
        let pitchDistribution = pitchCounts.map { Double($0) / Double(total) }
        
        // Test all keys
        var bestKey = "C major"
        var bestCorrelation = -1.0
        
        for tonic in 0..<12 {
            // Test major
            let majorCorr = correlation(pitchDistribution, rotated: majorProfile, by: tonic)
            if majorCorr > bestCorrelation {
                bestCorrelation = majorCorr
                bestKey = "\(noteNames[tonic]) major"
            }
            
            // Test minor
            let minorCorr = correlation(pitchDistribution, rotated: minorProfile, by: tonic)
            if minorCorr > bestCorrelation {
                bestCorrelation = minorCorr
                bestKey = "\(noteNames[tonic]) minor"
            }
        }
        
        return bestKey
    }
    
    // MARK: - Helper Methods
    private func correlation(_ distribution: [Double], rotated profile: [Double], by offset: Int) -> Double {
        var rotatedProfile = profile
        
        // Rotate profile
        for _ in 0..<offset {
            let first = rotatedProfile.removeFirst()
            rotatedProfile.append(first)
        }
        
        // Calculate Pearson correlation
        let meanDist = distribution.reduce(0, +) / Double(distribution.count)
        let meanProf = rotatedProfile.reduce(0, +) / Double(rotatedProfile.count)
        
        var numerator = 0.0
        var denomDist = 0.0
        var denomProf = 0.0
        
        for i in 0..<12 {
            let distDiff = distribution[i] - meanDist
            let profDiff = rotatedProfile[i] - meanProf
            numerator += distDiff * profDiff
            denomDist += distDiff * distDiff
            denomProf += profDiff * profDiff
        }
        
        let denominator = sqrt(denomDist * denomProf)
        return denominator > 0 ? numerator / denominator : 0
    }
}

