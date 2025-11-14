//
//  AudioStem.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Stem
class AudioStem: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let buffer: AVAudioPCMBuffer
    let sourceURL: URL?  // Original file URL (for guitar)
    
    @Published var level: Float = 1.0      // 0.0 - 2.0
    @Published var isMuted: Bool = false
    @Published var isSoloed: Bool = false
    
    init(name: String, buffer: AVAudioPCMBuffer, sourceURL: URL? = nil) {
        self.name = name
        self.buffer = buffer
        self.sourceURL = sourceURL
    }
    
    var levelDB: Float {
        20 * log10(max(level, 0.001))
    }
}

// MARK: - Stem Collection
class StemCollection: ObservableObject {
    @Published var stems: [AudioStem] = []
    @Published var masterLevel: Float = 1.0
    
    var hasSoloedStems: Bool {
        stems.contains { $0.isSoloed }
    }
    
    func addStem(_ stem: AudioStem) {
        stems.append(stem)
    }
    
    func removeStem(_ stem: AudioStem) {
        stems.removeAll { $0.id == stem.id }
    }
    
    func clearAll() {
        stems.removeAll()
    }
    
    // Calculate effective level for each stem considering solo/mute
    func effectiveLevel(for stem: AudioStem) -> Float {
        if stem.isMuted {
            return 0.0
        }
        
        if hasSoloedStems {
            return stem.isSoloed ? stem.level : 0.0
        }
        
        return stem.level
    }
}
