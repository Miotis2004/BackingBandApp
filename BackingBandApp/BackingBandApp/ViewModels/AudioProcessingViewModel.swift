import SwiftUI
import AudioKit
import AVFoundation
import Combine

@MainActor
class AudioProcessingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var inputFileURL: URL?
    @Published var outputFileURL: URL?
    @Published var selectedGenre: Genre = .rock
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var statusMessage = "Ready to generate backing band"
    @Published var errorMessage: String?
    
    // Analysis results
    @Published var analysis: MusicAnalysis?
    @Published var guitarTrack: MIDITrack?
    @Published var drumsTrack: MIDITrack?
    @Published var bassTrack: MIDITrack?
    
    // MARK: - Services
    let audioPlayer = AudioPlayerService()
    private let transcriptionService = TranscriptionService()
    private let analysisService = AnalysisService()
    private let drumGenerator = DrumGenerator()
    private let bassGenerator = BassGenerator()
    private let audioRenderer = AudioRenderer()
    
    init() {
        // Services are initialized above
    }
    
    // MARK: - Main Processing Pipeline
    func processAudioFile() async {
        guard let inputURL = inputFileURL else {
            errorMessage = "No input file selected"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        progress = 0
        
        // Run the heavy work on a background thread
        Task.detached { [weak self] in
            guard let self else { return }
            
            do {
                // Step 1: Transcribe audio to MIDI (OFF MAIN THREAD)
                await MainActor.run {
                    self.statusMessage = "Transcribing guitar..."
                    self.progress = 0.1
                }
                
                let guitarTrack = try await self.transcriptionService.transcribe(inputURL) { transcriptionProgress, message in
                    Task { @MainActor in
                        self.progress = 0.1 + (transcriptionProgress * 0.2)
                        self.statusMessage = message
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.guitarTrack = guitarTrack
                    self.statusMessage = "Transcription complete! Found \(guitarTrack.notes.count) notes"
                    self.progress = 1.0
                }
                
                // Step 2: Analyze music structure
                await MainActor.run {
                    self.statusMessage = "Analyzing music structure..."
                    self.progress = 0.3
                }
                
                let analysis = try await self.analysisService.analyze(guitarTrack)
                
                await MainActor.run {
                    self.analysis = analysis
                    self.progress = 0.5
                }
                
                // Step 3: Generate drums
                await MainActor.run {
                    self.statusMessage = "Generating drums..."
                }
                
                let drumsTrack = try await self.drumGenerator.generate(analysis: analysis, genre: await self.selectedGenre)
                
                await MainActor.run {
                    self.drumsTrack = drumsTrack
                    self.progress = 0.7
                }
                
                // Step 4: Generate bass
                await MainActor.run {
                    self.statusMessage = "Generating bass..."
                }
                
                let bassTrack = try await self.bassGenerator.generate(analysis: analysis, genre: await self.selectedGenre)
                
                await MainActor.run {
                    self.bassTrack = bassTrack
                    self.progress = 0.9
                    self.statusMessage = "Rendering audio..."
                }
                
                // Step 5: Render to audio
                let outputURL = await MainActor.run {
                    self.createOutputURL()
                }
                
                var tracks: [MIDITrack] = []
                tracks.append(drumsTrack)
                tracks.append(bassTrack)
                
                try await self.audioRenderer.render(tracks: tracks, outputURL: outputURL)
                
                await MainActor.run {
                    self.outputFileURL = outputURL
                    self.progress = 1.0
                    self.statusMessage = "Complete! 🎵"
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Error occurred"
                }
                print("Processing error: \(error)")
            }
            
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - File Selection
    func selectInputFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .wav, .aiff, .mp3]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a guitar audio file"
        
        if panel.runModal() == .OK, let url = panel.url {
            inputFileURL = url
            
            // Load audio into player
            do {
                try audioPlayer.loadAudioFile(url: url)
                statusMessage = "Loaded: \(url.lastPathComponent)"
                errorMessage = nil
            } catch {
                errorMessage = "Failed to load audio: \(error.localizedDescription)"
                statusMessage = "Error loading file"
            }
            
            // Reset state
            analysis = nil
            guitarTrack = nil
            drumsTrack = nil
            bassTrack = nil
            outputFileURL = nil
        }
    }
    
    func selectOutputLocation() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.wav]
        panel.nameFieldStringValue = "backing_track.wav"
        panel.message = "Save backing track as"
        
        if panel.runModal() == .OK {
            outputFileURL = panel.url
        }
    }
    
    // MARK: - Helper Methods
    private func createOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "backing_track_\(timestamp).wav"
        return documentsPath.appendingPathComponent(filename)
    }
    
    // MARK: - Reset
    func reset() {
        audioPlayer.stop()
        inputFileURL = nil
        outputFileURL = nil
        analysis = nil
        guitarTrack = nil
        drumsTrack = nil
        bassTrack = nil
        errorMessage = nil
        statusMessage = "Ready to generate backing band"
        progress = 0
        isProcessing = false
    }
}

// MARK: - Processing Errors
enum ProcessingError: LocalizedError {
    case transcriptionFailed
    case analysisFailed
    case generationFailed
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Failed to transcribe audio to MIDI"
        case .analysisFailed:
            return "Failed to analyze music structure"
        case .generationFailed:
            return "Failed to generate backing tracks"
        case .renderingFailed:
            return "Failed to render audio output"
        }
    }
}
