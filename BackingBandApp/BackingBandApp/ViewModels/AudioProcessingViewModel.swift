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
        
        do {
            // Step 1: Transcribe audio to MIDI
            statusMessage = "Transcribing guitar..."
            progress = 0.1
            guitarTrack = try await transcriptionService.transcribe(inputURL)
            
            // Step 2: Analyze music structure
            guard let guitarTrack = guitarTrack else {
                throw ProcessingError.transcriptionFailed
            }
            statusMessage = "Analyzing music structure..."
            progress = 0.3
            analysis = try await analysisService.analyze(guitarTrack)
            
            // Step 3: Generate drums
            guard let analysis = analysis else {
                throw ProcessingError.analysisFailed
            }
            statusMessage = "Generating drums..."
            progress = 0.5
            drumsTrack = try await drumGenerator.generate(analysis: analysis, genre: selectedGenre)
            
            // Step 4: Generate bass
            statusMessage = "Generating bass..."
            progress = 0.7
            bassTrack = try await bassGenerator.generate(analysis: analysis, genre: selectedGenre)
            
            // Step 5: Render to audio
            statusMessage = "Rendering audio..."
            progress = 0.9
            
            // Create output URL
            let outputURL = createOutputURL()
            outputFileURL = outputURL
            
            // Render all tracks
            var tracks: [MIDITrack] = []
            if let drums = drumsTrack { tracks.append(drums) }
            if let bass = bassTrack { tracks.append(bass) }
            
            try await audioRenderer.render(tracks: tracks, outputURL: outputURL)
            
            progress = 1.0
            statusMessage = "Complete! 🎵"
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Error occurred"
            print("Processing error: \(error)")
        }
        
        isProcessing = false
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
