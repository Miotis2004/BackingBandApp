//
//  AudioSevices.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation
import AVFoundation

// Placeholder services - we'll implement these next

class TranscriptionService {
    private let pitchDetector = PitchDetectionService()
    private let noteSegmenter = NoteSegmentationService()
    
    func transcribe(_ audioURL: URL, progressHandler: ((Double, String) -> Void)? = nil) async throws -> MIDITrack {
        
        // Step 1: Detect pitches
        progressHandler?(0.0, "Detecting pitches...")
        
        let pitchResults = try await pitchDetector.detectPitches(from: audioURL) { progress in
            progressHandler?(progress * 0.7, "Analyzing audio... \(Int(progress * 100))%")
        }
        
        progressHandler?(0.7, "Detected \(pitchResults.count) pitch points")
        
        // Step 2: Segment into notes
        progressHandler?(0.8, "Converting to notes...")
        
        let notes = noteSegmenter.segmentNotes(from: pitchResults)
        
        progressHandler?(0.9, "Found \(notes.count) notes")
        
        // Step 3: Create MIDI track
        let track = MIDITrack(
            name: "Guitar",
            notes: notes,
            instrument: "Guitar"
        )
        
        progressHandler?(1.0, "Transcription complete!")
        
        return track
    }
}

class AnalysisService {
    private let tempoDetector = TempoDetectionService()
    private let keyDetector = KeyDetectionService()
    private let chordDetector = ChordDetectionService()
    
    func analyze(_ track: MIDITrack) async throws -> MusicAnalysis {
        print("🎼 Starting music analysis...")
        
        // Run on background thread
        return await Task.detached(priority: .userInitiated) {
            // Detect tempo
            print("⏱️ Detecting tempo...")
            let tempo = self.tempoDetector.detectTempo(from: track)
            print("✅ Tempo: \(tempo) BPM")
            
            // Detect time signature
            let timeSignature = self.tempoDetector.detectTimeSignature(from: track, tempo: tempo)
            
            // Detect key
            print("🎹 Detecting key...")
            let key = self.keyDetector.detectKey(from: track)
            print("✅ Key: \(key)")
            
            // Detect chords
            print("🎸 Detecting chords...")
            let chords = self.chordDetector.detectChords(from: track, tempo: tempo)
            print("✅ Found \(chords.count) chords")
            
            // Detect song structure (simplified for now)
            let totalDuration = track.notes.map { $0.startTime + $0.duration }.max() ?? 0
            let sections = [
                SongSection(type: .verse, startTime: 0, endTime: totalDuration)
            ]
            
            return MusicAnalysis(
                tempo: tempo,
                timeSignature: timeSignature,
                key: key,
                chords: chords,
                sections: sections,
                totalDuration: totalDuration
            )
        }.value
    }
}

class DrumGenerator {
    
    func generate(analysis: MusicAnalysis, genre: Genre) async throws -> MIDITrack {
        print("🥁 Generating drums for \(genre.displayName)...")
        
        return await Task.detached(priority: .userInitiated) {
            var drumNotes: [MIDINote] = []
            
            // Get patterns for this genre
            let groovePatterns = DrumPatternLibrary.patterns(for: genre)
            let fillPatterns = DrumPatternLibrary.fills()
            
            guard !groovePatterns.isEmpty else {
                print("❌ No patterns available for genre")
                return MIDITrack(name: "Drums", notes: [], instrument: "Drums")
            }
            
            // Calculate beats per second
            let beatsPerSecond = analysis.tempo / 60.0
            let secondsPerBeat = 1.0 / beatsPerSecond
            
            // Generate drums for each section
            for section in analysis.sections {
                print("🎵 Generating drums for \(section.type.rawValue) section")
                
                let sectionDuration = section.endTime - section.startTime
                let numberOfBars = Int(ceil(sectionDuration / (secondsPerBeat * 4.0)))
                
                // Select pattern based on section type
                let groovePattern: DrumPattern
                if section.type == .chorus && groovePatterns.count > 1 {
                    groovePattern = groovePatterns[1] // More energetic for chorus
                } else {
                    groovePattern = groovePatterns[0]
                }
                
                // Generate bars
                for bar in 0..<numberOfBars {
                    let barStartTime = section.startTime + (Double(bar) * secondsPerBeat * 4.0)
                    
                    // Add fill on last bar of section (if not last bar)
                    let isLastBarOfSection = (bar == numberOfBars - 1)
                    let shouldAddFill = isLastBarOfSection && fillPatterns.count > 0
                    
                    if shouldAddFill {
                        // Add fill
                        let fill = fillPatterns.randomElement()!
                        let fillNotes = self.convertPatternToNotes(
                            pattern: fill,
                            startTime: barStartTime,
                            tempo: analysis.tempo
                        )
                        drumNotes.append(contentsOf: fillNotes)
                    } else {
                        // Add regular groove
                        let notes = self.convertPatternToNotes(
                            pattern: groovePattern,
                            startTime: barStartTime,
                            tempo: analysis.tempo
                        )
                        drumNotes.append(contentsOf: notes)
                    }
                }
            }
            
            print("✅ Generated \(drumNotes.count) drum hits")
            
            return MIDITrack(
                name: "Drums",
                notes: drumNotes,
                instrument: "Drums"
            )
        }.value
    }
    
    // MARK: - Convert Pattern to Notes
    private func convertPatternToNotes(pattern: DrumPattern, startTime: TimeInterval, tempo: Double) -> [MIDINote] {
        let secondsPerBeat = 60.0 / tempo
        var notes: [MIDINote] = []
        
        for hit in pattern.beats {
            let noteStartTime = startTime + (hit.position * secondsPerBeat)
            let noteDuration = 0.1 // Short duration for drums
            
            let note = MIDINote(
                pitch: hit.drum.rawValue,
                velocity: hit.velocity,
                startTime: noteStartTime,
                duration: noteDuration,
                channel: 9 // MIDI channel 10 (index 9) is drums
            )
            
            notes.append(note)
        }
        
        return notes
    }
}

class BassGenerator {
    
    // MARK: - Note name to MIDI number mapping
    private let noteToMIDI: [String: Int] = [
        "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
        "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11
    ]
    
    func generate(analysis: MusicAnalysis, genre: Genre) async throws -> MIDITrack {
        print("🎸 Generating bass for \(genre.displayName)...")
        
        return await Task.detached(priority: .userInitiated) {
            var bassNotes: [MIDINote] = []
            
            // Get patterns for this genre
            let patterns = BassPatternLibrary.patterns(for: genre)
            
            guard !patterns.isEmpty else {
                print("❌ No bass patterns available for genre")
                return MIDITrack(name: "Bass", notes: [], instrument: "Bass")
            }
            
            // Calculate beats per second
            let beatsPerSecond = analysis.tempo / 60.0
            let secondsPerBeat = 1.0 / beatsPerSecond
            
            // Select primary pattern (can vary later)
            let primaryPattern = patterns[0]
            let alternatePattern = patterns.count > 1 ? patterns[1] : primaryPattern
            
            // Generate bass for each chord
            for (index, chord) in analysis.chords.enumerated() {
                print("🎵 Bass for chord: \(chord.displayName)")
                
                // Get root note MIDI number
                guard let rootMIDI = self.getRootMIDI(for: chord) else {
                    print("⚠️ Could not determine root for \(chord.root)")
                    continue
                }
                
                // Select pattern (vary for interest)
                let useAlternate = (index % 4 == 2 || index % 4 == 3) && patterns.count > 1
                let pattern = useAlternate ? alternatePattern : primaryPattern
                
                // Calculate how many times to repeat the pattern for this chord duration
                let patternDuration = Double(pattern.beatsPerBar) * secondsPerBeat
                let repetitions = Int(ceil(chord.duration / patternDuration))
                
                // Generate notes for each repetition
                for rep in 0..<repetitions {
                    let patternStartTime = chord.startTime + (Double(rep) * patternDuration)
                    
                    // Stop if we've gone past the chord duration
                    guard patternStartTime < chord.startTime + chord.duration else { break }
                    
                    let notes = self.convertPatternToNotes(
                        pattern: pattern,
                        rootMIDI: rootMIDI,
                        startTime: patternStartTime,
                        tempo: analysis.tempo,
                        chordDuration: chord.duration - (Double(rep) * patternDuration)
                    )
                    
                    bassNotes.append(contentsOf: notes)
                }
            }
            
            print("✅ Generated \(bassNotes.count) bass notes")
            
            return MIDITrack(
                name: "Bass",
                notes: bassNotes,
                instrument: "Bass"
            )
        }.value
    }
    
    // MARK: - Get Root MIDI Note
    private func getRootMIDI(for chord: Chord) -> Int? {
        // Remove any modifiers (like "maj", "m") to get just the note name
        let noteName = chord.root.replacingOccurrences(of: "♯", with: "#")
                                  .replacingOccurrences(of: "♭", with: "b")
        
        // Handle flats (convert to sharp equivalents)
        let normalizedNote: String
        if noteName.contains("b") {
            let flatMap: [String: String] = [
                "Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"
            ]
            normalizedNote = flatMap[noteName] ?? noteName.replacingOccurrences(of: "b", with: "")
        } else {
            normalizedNote = noteName
        }
        
        guard let pitchClass = noteToMIDI[normalizedNote] else {
            return nil
        }
        
        // Bass typically plays in octaves 1-3 (MIDI 36-60)
        // Use octave 2 (MIDI 36-47) as default
        let bassMIDI = 36 + pitchClass  // E1 = 28, so 36 = C2
        
        return bassMIDI
    }
    
    // MARK: - Convert Pattern to Notes
    private func convertPatternToNotes(
        pattern: BassPattern,
        rootMIDI: Int,
        startTime: TimeInterval,
        tempo: Double,
        chordDuration: TimeInterval
    ) -> [MIDINote] {
        
        let secondsPerBeat = 60.0 / tempo
        var notes: [MIDINote] = []
        
        for bassNote in pattern.notes {
            let noteStartTime = startTime + (bassNote.position * secondsPerBeat)
            
            // Don't add notes that would go past the chord change
            guard noteStartTime < startTime + chordDuration else { continue }
            
            // Calculate MIDI note with offset
            let octaveShift = bassNote.octaveOffset * 12
            let midiNote = rootMIDI + bassNote.rootOffset + octaveShift
            
            // Clamp to valid MIDI range (keep in bass range)
            let clampedMIDI = max(28, min(60, midiNote))
            
            let noteDuration = min(bassNote.duration * secondsPerBeat, chordDuration - (bassNote.position * secondsPerBeat))
            
            let note = MIDINote(
                pitch: UInt8(clampedMIDI),
                velocity: bassNote.velocity,
                startTime: noteStartTime,
                duration: noteDuration,
                channel: 0  // Bass on channel 1
            )
            
            notes.append(note)
        }
        
        return notes
    }
}

class AudioRenderer {
    func render(tracks: [MIDITrack], outputURL: URL) async throws {
        // TODO: Implement rendering
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
