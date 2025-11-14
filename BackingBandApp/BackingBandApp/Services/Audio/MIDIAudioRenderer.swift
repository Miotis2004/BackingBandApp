//
//  MIDIAudioRenderer.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation
import AVFoundation
import AudioKit

class MIDIAudioRenderer {
    
    private let engine = AVAudioEngine()
    private var sampler: AVAudioUnitSampler?
    
    // MARK: - Render MIDI Track to Audio Buffer
    func renderToAudio(
        midiTrack: MIDITrack,
        sampleRate: Double = 44100,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> AVAudioPCMBuffer {
        
        print("🎹 Rendering \(midiTrack.name) to audio...")
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Calculate total duration
                    let totalDuration = midiTrack.notes.map { $0.startTime + $0.duration }.max() ?? 0
                    let bufferLength = Int(totalDuration * sampleRate) + Int(sampleRate) // Add 1 second padding
                    
                    guard bufferLength > 0 else {
                        throw RenderError.invalidDuration
                    }
                    
                    print("📊 Buffer length: \(bufferLength) samples (\(totalDuration)s)")
                    
                    // Create output buffer
                    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
                    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferLength)) else {
                        throw RenderError.bufferCreationFailed
                    }
                    outputBuffer.frameLength = AVAudioFrameCount(bufferLength)
                    
                    // Zero out buffer
                    if let channelData = outputBuffer.floatChannelData {
                        for channel in 0..<Int(format.channelCount) {
                            memset(channelData[channel], 0, Int(outputBuffer.frameLength) * MemoryLayout<Float>.size)
                        }
                    }
                    
                    // Load appropriate instrument
                    let soundfontPath = self.getSoundfontPath(for: midiTrack.instrument)
                    
                    // Render each note
                    for (index, note) in midiTrack.notes.enumerated() {
                        self.renderNote(
                            note: note,
                            into: outputBuffer,
                            sampleRate: sampleRate,
                            instrument: midiTrack.instrument
                        )
                        
                        if index % 100 == 0 {
                            let progress = Double(index) / Double(midiTrack.notes.count)
                            DispatchQueue.main.async {
                                progressHandler?(progress)
                            }
                        }
                    }
                    
                    print("✅ Rendered \(midiTrack.notes.count) notes")
                    continuation.resume(returning: outputBuffer)
                    
                } catch {
                    print("❌ Render error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Render Individual Note
    private func renderNote(
        note: MIDINote,
        into buffer: AVAudioPCMBuffer,
        sampleRate: Double,
        instrument: String
    ) {
        let startFrame = Int(note.startTime * sampleRate)
        let durationFrames = Int(note.duration * sampleRate)
        let endFrame = min(startFrame + durationFrames, Int(buffer.frameLength))
        
        guard let channelData = buffer.floatChannelData else { return }
        
        // Generate a simple tone based on MIDI note
        let frequency = midiNoteToFrequency(note.pitch)
        
        // BOOST AMPLITUDE - Changed from 0.3 to 2.0 for drums/bass
        let baseAmplitude = Float(note.velocity) / 127.0
        let amplitude = instrument == "Drums" ? baseAmplitude * 3.0 : baseAmplitude * 2.5
        
        // Apply envelope (ADSR)
        let attackFrames = Int(0.01 * sampleRate)  // 10ms attack
        let releaseFrames = Int(0.05 * sampleRate) // 50ms release
        
        for frame in startFrame..<endFrame {
            let localFrame = frame - startFrame
            let t = Double(localFrame) / sampleRate
            
            // Generate tone
            var sample = sin(2.0 * .pi * frequency * t) * Double(amplitude)
            
            // Apply envelope
            var envelope: Double = 1.0
            if localFrame < attackFrames {
                envelope = Double(localFrame) / Double(attackFrames)
            } else if localFrame > durationFrames - releaseFrames {
                let releaseProgress = Double(durationFrames - localFrame) / Double(releaseFrames)
                envelope = releaseProgress
            }
            
            sample *= envelope
            
            // Add to both channels
            if frame < buffer.frameLength {
                channelData[0][frame] += Float(sample)
                channelData[1][frame] += Float(sample)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func midiNoteToFrequency(_ midiNote: UInt8) -> Double {
        return 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
    }
    
    private func getSoundfontPath(for instrument: String) -> String {
        // Placeholder - will implement proper soundfont loading later
        return ""
    }
}

enum RenderError: LocalizedError {
    case invalidDuration
    case bufferCreationFailed
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Invalid audio duration"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .renderingFailed:
            return "Audio rendering failed"
        }
    }
}

