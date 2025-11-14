import Foundation
import AVFoundation
import AudioKit

class MIDIAudioRenderer {
    
    // MARK: - Render MIDI Track to Audio Buffer
    func renderToAudio(
        midiTrack: MIDITrack,
        sampleRate: Double = 44100,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> AVAudioPCMBuffer {
        
        print("🎹 Rendering \(midiTrack.name) to audio (synthesis mode)...")
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Calculate total duration
                    let totalDuration = midiTrack.notes.map { $0.startTime + $0.duration }.max() ?? 0
                    let bufferDuration = totalDuration + 1.0 // Add 1 second padding
                    let bufferLength = Int(bufferDuration * sampleRate)
                    
                    guard bufferLength > 0 else {
                        throw RenderError.invalidDuration
                    }
                    
                    print("📊 Rendering \(totalDuration)s + padding = \(bufferDuration)s")
                    
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
                    
                    // Render each note
                    print("🎵 Rendering \(midiTrack.notes.count) notes...")
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
    
    // MARK: - Render Individual Note with Improved Synthesis
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
        
        let frequency = midiNoteToFrequency(note.pitch)
        let baseAmplitude = Float(note.velocity) / 127.0
        
        // Different synthesis for different instruments
        switch instrument {
        case "Drums":
            renderDrumHit(
                pitch: note.pitch,
                velocity: baseAmplitude,
                startFrame: startFrame,
                endFrame: endFrame,
                buffer: buffer,  // Pass the whole buffer instead
                sampleRate: sampleRate
            )
            
        case "Bass":
            renderBassNote(
                frequency: frequency,
                velocity: baseAmplitude,
                startFrame: startFrame,
                endFrame: endFrame,
                buffer: buffer,  // Pass the whole buffer instead
                sampleRate: sampleRate
            )
            
        default:
            renderSineNote(
                frequency: frequency,
                velocity: baseAmplitude,
                startFrame: startFrame,
                endFrame: endFrame,
                buffer: buffer,  // Pass the whole buffer instead
                sampleRate: sampleRate
            )
        }
    }

    // MARK: - Drum Synthesis
    private func renderDrumHit(
        pitch: UInt8,
        velocity: Float,
        startFrame: Int,
        endFrame: Int,
        buffer: AVAudioPCMBuffer,  // Changed parameter
        sampleRate: Double
    ) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let amplitude = velocity * 2.0
        
        switch pitch {
        case 36: // Kick drum
            for frame in startFrame..<endFrame {
                guard frame < buffer.frameLength else { break }
                let localFrame = frame - startFrame
                let t = Double(localFrame) / sampleRate
                
                let pitchEnv = 100.0 * exp(-t * 30.0)
                let noise = Float.random(in: -0.3...0.3)
                let tone = sin(2.0 * .pi * pitchEnv * t)
                
                let env = exp(-Double(localFrame) / (sampleRate * 0.15))
                let sample = Float((tone + Double(noise)) * env * Double(amplitude))
                
                channelData[0][frame] += sample
                channelData[1][frame] += sample
            }
            
        case 38, 40: // Snare
            for frame in startFrame..<endFrame {
                guard frame < buffer.frameLength else { break }
                let localFrame = frame - startFrame
                let t = Double(localFrame) / sampleRate
                
                let tone = sin(2.0 * .pi * 200.0 * t) * 0.3
                let noise = Float.random(in: -0.7...0.7)
                
                let env = exp(-Double(localFrame) / (sampleRate * 0.1))
                let sample = Float((tone + Double(noise)) * env * Double(amplitude))
                
                channelData[0][frame] += sample
                channelData[1][frame] += sample
            }
            
        case 42, 44: // Hi-hat (closed)
            for frame in startFrame..<min(startFrame + Int(sampleRate * 0.05), endFrame) {
                guard frame < buffer.frameLength else { break }
                let noise = Float.random(in: -0.5...0.5) * amplitude * 0.8
                let env = Float(exp(-Double(frame - startFrame) / (sampleRate * 0.02)))
                
                channelData[0][frame] += noise * env
                channelData[1][frame] += noise * env
            }
            
        case 46, 26: // Hi-hat (open)
            for frame in startFrame..<min(startFrame + Int(sampleRate * 0.2), endFrame) {
                guard frame < buffer.frameLength else { break }
                let noise = Float.random(in: -0.4...0.4) * amplitude * 0.7
                let env = Float(exp(-Double(frame - startFrame) / (sampleRate * 0.1)))
                
                channelData[0][frame] += noise * env
                channelData[1][frame] += noise * env
            }
            
        case 49, 57: // Crash cymbal
            for frame in startFrame..<min(startFrame + Int(sampleRate * 0.8), endFrame) {
                guard frame < buffer.frameLength else { break }
                let noise = Float.random(in: -0.6...0.6) * amplitude
                let env = Float(exp(-Double(frame - startFrame) / (sampleRate * 0.4)))
                
                channelData[0][frame] += noise * env
                channelData[1][frame] += noise * env
            }
            
        default: // Other drums - generic tom sound
            for frame in startFrame..<endFrame {
                guard frame < buffer.frameLength else { break }
                let localFrame = frame - startFrame
                let t = Double(localFrame) / sampleRate
                
                let freq = midiNoteToFrequency(pitch)
                let tone = sin(2.0 * .pi * freq * t)
                let env = exp(-Double(localFrame) / (sampleRate * 0.2))
                
                let sample = Float(tone * env * Double(amplitude))
                
                channelData[0][frame] += sample
                channelData[1][frame] += sample
            }
        }
    }

    // MARK: - Bass Synthesis
    private func renderBassNote(
        frequency: Double,
        velocity: Float,
        startFrame: Int,
        endFrame: Int,
        buffer: AVAudioPCMBuffer,  // Changed parameter
        sampleRate: Double
    ) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let durationFrames = endFrame - startFrame
        let amplitude = velocity * 2.5
        
        let attackFrames = Int(0.01 * sampleRate)
        let releaseFrames = Int(0.05 * sampleRate)
        
        for frame in startFrame..<endFrame {
            guard frame < buffer.frameLength else { break }
            let localFrame = frame - startFrame
            let t = Double(localFrame) / sampleRate
            
            let sine = sin(2.0 * .pi * frequency * t)
            let square = sin(2.0 * .pi * frequency * t) > 0 ? 0.3 : -0.3
            let sample = (sine * 0.7 + square * 0.3) * Double(amplitude)
            
            var envelope: Double = 1.0
            if localFrame < attackFrames {
                envelope = Double(localFrame) / Double(attackFrames)
            } else if localFrame > durationFrames - releaseFrames {
                envelope = Double(durationFrames - localFrame) / Double(releaseFrames)
            }
            
            let finalSample = Float(sample * envelope)
            
            channelData[0][frame] += finalSample
            channelData[1][frame] += finalSample
        }
    }

    // MARK: - Sine Note Synthesis
    private func renderSineNote(
        frequency: Double,
        velocity: Float,
        startFrame: Int,
        endFrame: Int,
        buffer: AVAudioPCMBuffer,  // Changed parameter
        sampleRate: Double
    ) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let durationFrames = endFrame - startFrame
        let amplitude = velocity * 1.5
        
        let attackFrames = Int(0.01 * sampleRate)
        let releaseFrames = Int(0.05 * sampleRate)
        
        for frame in startFrame..<endFrame {
            guard frame < buffer.frameLength else { break }
            let localFrame = frame - startFrame
            let t = Double(localFrame) / sampleRate
            
            var sample = sin(2.0 * .pi * frequency * t) * Double(amplitude)
            
            var envelope: Double = 1.0
            if localFrame < attackFrames {
                envelope = Double(localFrame) / Double(attackFrames)
            } else if localFrame > durationFrames - releaseFrames {
                envelope = Double(durationFrames - localFrame) / Double(releaseFrames)
            }
            
            sample *= envelope
            
            channelData[0][frame] += Float(sample)
            channelData[1][frame] += Float(sample)
        }
    }

    // MARK: - Helper
    private func midiNoteToFrequency(_ midiNote: UInt8) -> Double {
        return 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
    }
}
