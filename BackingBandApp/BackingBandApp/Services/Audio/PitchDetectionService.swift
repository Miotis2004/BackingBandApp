//
//  PitchDetectionService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation
import AVFoundation
import AudioKit

class PitchDetectionService {
    
    // MARK: - Pitch Detection Result
    struct PitchResult {
        let frequency: Float      // Hz
        let confidence: Float     // 0.0 - 1.0
        let time: TimeInterval    // Seconds into the audio
        
        var midiNote: UInt8? {
            guard confidence > 0.5 else { return nil }
            return frequencyToMIDI(frequency)
        }
        
        private func frequencyToMIDI(_ frequency: Float) -> UInt8 {
            // MIDI note = 69 + 12 * log2(frequency / 440)
            // MIDI 69 = A4 = 440 Hz
            let noteNumber = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
            return UInt8(max(0, min(127, round(noteNumber))))
        }
    }
    
    /// MARK: - Detect Pitches
    func detectPitches(from audioURL: URL,
                      hopSize: Int = 2048,
                      progressHandler: ((Double) -> Void)? = nil) async throws -> [PitchResult] {
        
        // Ensure we're NOT on the main thread
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Load audio file
                    let audioFile = try AVAudioFile(forReading: audioURL)
                    let format = audioFile.processingFormat
                    let frameCount = AVAudioFrameCount(audioFile.length)
                    
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                        throw TranscriptionError.bufferCreationFailed
                    }
                    
                    try audioFile.read(into: buffer)
                    
                    guard let channelData = buffer.floatChannelData else {
                        throw TranscriptionError.noAudioData
                    }
                    
                    let sampleRate = format.sampleRate
                    let channelDataValue = channelData[0]
                    let totalSamples = Int(buffer.frameLength)
                    
                    var results: [PitchResult] = []
                    
                    // Process audio in chunks
                    let fftSize = 2048
                    var position = 0
                    
                    print("🎵 Starting pitch detection on \(totalSamples) samples")
                    
                    while position + fftSize < totalSamples {
                        let chunk = Array(UnsafeBufferPointer(
                            start: channelDataValue.advanced(by: position),
                            count: fftSize
                        ))
                        
                        // Detect pitch for this chunk
                        if let pitch = self.detectPitchInChunk(chunk, sampleRate: Float(sampleRate)) {
                            let time = Double(position) / sampleRate
                            let result = PitchResult(
                                frequency: pitch.frequency,
                                confidence: pitch.confidence,
                                time: time
                            )
                            results.append(result)
                        }
                        
                        position += hopSize
                        
                        // Report progress every 1000 chunks
                        if results.count % 1000 == 0 {
                            let progress = Double(position) / Double(totalSamples)
                            DispatchQueue.main.async {
                                progressHandler?(progress)
                            }
                            print("Progress: \(Int(progress * 100))%")
                        }
                    }
                    
                    print("✅ Pitch detection complete: \(results.count) points")
                    continuation.resume(returning: results)
                    
                } catch {
                    print("❌ Pitch detection error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Pitch Detection Algorithm
    private func detectPitchInChunk(_ samples: [Float], sampleRate: Float) -> (frequency: Float, confidence: Float)? {
        // Use autocorrelation method for pitch detection
        let minFreq: Float = 80.0   // ~E2
        let maxFreq: Float = 1000.0 // ~B5
        
        let minPeriod = Int(sampleRate / maxFreq)
        let maxPeriod = Int(sampleRate / minFreq)
        
        guard maxPeriod < samples.count else { return nil }
        
        // Calculate autocorrelation
        var bestPeriod = minPeriod
        var maxCorrelation: Float = 0.0
        
        for period in minPeriod...maxPeriod {
            var correlation: Float = 0.0
            for i in 0..<(samples.count - period) {
                correlation += samples[i] * samples[i + period]
            }
            
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestPeriod = period
            }
        }
        
        // Calculate confidence based on correlation strength
        let energy = samples.reduce(0) { $0 + $1 * $1 }
        let confidence = energy > 0 ? min(1.0, maxCorrelation / energy) : 0.0
        
        let frequency = sampleRate / Float(bestPeriod)
        
        return (frequency: frequency, confidence: confidence)
    }
}

// MARK: - Errors
enum TranscriptionError: LocalizedError {
    case bufferCreationFailed
    case noAudioData
    case pitchDetectionFailed
    
    var errorDescription: String? {
        switch self {
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .noAudioData:
            return "No audio data found in file"
        case .pitchDetectionFailed:
            return "Pitch detection failed"
        }
    }
}

