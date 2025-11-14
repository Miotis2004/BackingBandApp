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
    
    @Published var stemCollection: StemCollection?
    let stemPlayer = StemPlayerService()
    
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
            
            Task.detached { [weak self] in
                guard let self else { return }
                
                do {
                    // Step 1: Transcribe
                    await MainActor.run {
                        self.statusMessage = "Transcribing guitar..."
                        self.progress = 0.1
                    }
                    
                    let guitarTrack = try await self.transcriptionService.transcribe(inputURL) { transcriptionProgress, message in
                        Task { @MainActor in
                            self.progress = 0.1 + (transcriptionProgress * 0.15)
                            self.statusMessage = message
                        }
                    }
                    
                    await MainActor.run {
                        self.guitarTrack = guitarTrack
                    }
                    
                    // Step 2: Analyze
                    await MainActor.run {
                        self.statusMessage = "Analyzing music structure..."
                        self.progress = 0.25
                    }
                    
                    let analysis = try await self.analysisService.analyze(guitarTrack)
                    
                    await MainActor.run {
                        self.analysis = analysis
                        self.progress = 0.35
                    }
                    
                    // Step 3: Generate drums
                    await MainActor.run {
                        self.statusMessage = "Generating drums..."
                        self.progress = 0.4
                    }
                    
                    let drumsTrack = try await self.drumGenerator.generate(analysis: analysis, genre: await self.selectedGenre)
                    
                    await MainActor.run {
                        self.drumsTrack = drumsTrack
                        self.progress = 0.5
                    }
                    
                    // Step 4: Generate bass
                    await MainActor.run {
                        self.statusMessage = "Generating bass..."
                        self.progress = 0.55
                    }
                    
                    let bassTrack = try await self.bassGenerator.generate(analysis: analysis, genre: await self.selectedGenre)
                    
                    await MainActor.run {
                        self.bassTrack = bassTrack
                        self.progress = 0.6
                    }
                    
                    // Step 5: Render to audio stems
                    await MainActor.run {
                        self.statusMessage = "Rendering audio..."
                    }
                    
                    let stems = try await self.audioRenderer.render(
                            originalAudioURL: inputURL,
                            drumsTrack: drumsTrack,
                            bassTrack: bassTrack
                        ) { renderProgress, message in
                            Task { @MainActor in
                                self.progress = 0.6 + (renderProgress * 0.4)
                                self.statusMessage = message
                            }
                        }
                        
                        await MainActor.run {
                            self.stemCollection = stems
                            self.stemPlayer.loadStems(stems)  // ADD THIS LINE
                            self.progress = 1.0
                            self.statusMessage = "Complete! 🎵 Ready to preview and export"
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
    
    // MARK: - Export Functions
        func exportMixedAudio() async {
            guard let stems = stemCollection else { return }
            
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.wav]
            panel.nameFieldStringValue = "mixed_backing_track.wav"
            panel.message = "Export mixed audio"
            
            guard panel.runModal() == .OK, let outputURL = panel.url else { return }
            
            do {
                try await audioRenderer.mixAndExport(stems: stems, outputURL: outputURL)
                outputFileURL = outputURL
                statusMessage = "Exported to: \(outputURL.lastPathComponent)"
            } catch {
                errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        
        func exportSeparateStems() async {
            guard let stems = stemCollection else { return }
            
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.message = "Choose export folder for stems"
            
            guard panel.runModal() == .OK, let directory = panel.url else { return }
            
            do {
                let urls = try await audioRenderer.exportStems(stems: stems, outputDirectory: directory)
                statusMessage = "Exported \(urls.count) stems to: \(directory.lastPathComponent)"
            } catch {
                errorMessage = "Export failed: \(error.localizedDescription)"
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
