//
//  ContentView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AudioProcessingViewModel()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 200)
        } detail: {
            // Main content
            MainContentView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Generate") {
                    Task {
                        await viewModel.processAudioFile()
                    }
                }
                .disabled(viewModel.inputFileURL == nil || viewModel.isProcessing)
                .keyboardShortcut("g", modifiers: .command)
            }
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: AudioProcessingViewModel
    
    var body: some View {
        List {
            Section("Input") {
                VStack(alignment: .leading, spacing: 8) {
                    if let url = viewModel.inputFileURL {
                        Label(url.lastPathComponent, systemImage: "music.note")
                            .lineLimit(1)
                    } else {
                        Text("No file selected")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Select Audio File...") {
                        viewModel.selectInputFile()
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Settings") {
                Picker("Genre", selection: $viewModel.selectedGenre) {
                    ForEach(Genre.allCases, id: \.self) { genre in
                        Text(genre.displayName).tag(genre)
                    }
                }
            }
            
            Section("Output") {
                if let url = viewModel.outputFileURL {
                    Label(url.lastPathComponent, systemImage: "waveform")
                        .lineLimit(1)
                } else {
                    Text("Not yet generated")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct MainContentView: View {
    @ObservedObject var viewModel: AudioProcessingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Audio Player (when file is loaded)
            if let url = viewModel.inputFileURL {
                AudioPlayerView(
                    player: viewModel.audioPlayer,
                    audioURL: url
                )
                .padding()
                
                Divider()
            }
            
            // Status area
            VStack(spacing: 20) {
                if viewModel.isProcessing {
                    ProgressView(value: viewModel.progress) {
                        Text(viewModel.statusMessage)
                    }
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 400)
                } else if viewModel.inputFileURL == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Select an audio file to begin")
                            .font(.headline)
                        
                        Button("Choose File...") {
                            viewModel.selectInputFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Notes display (when available)
            if let guitarTrack = viewModel.guitarTrack {
                Divider()
                NotesDisplayView(track: guitarTrack)
                    .padding()
            }
            
            // Stem Mixer (when stems are available)
            if let stems = viewModel.stemCollection {
                StemMixerView(
                    stemCollection: stems,
                    stemPlayer: viewModel.stemPlayer,  // Pass the player
                    onExportMixed: {
                        Task {
                            await viewModel.exportMixedAudio()
                        }
                    },
                    onExportStems: {
                        Task {
                            await viewModel.exportSeparateStems()
                        }
                    }
                )
                .padding(.horizontal)
            }
            
            // Analysis display (when available)
            if let analysis = viewModel.analysis {
                Divider()
                AnalysisView(analysis: analysis)
                    .padding()
            }
        }
    }
}

// Keep your existing AnalysisView...
struct AnalysisView: View {
    let analysis: MusicAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Results")
                .font(.headline)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Tempo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(analysis.tempo)) BPM")
                        .font(.title3)
                }
                
                VStack(alignment: .leading) {
                    Text("Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.key)
                        .font(.title3)
                }
                
                VStack(alignment: .leading) {
                    Text("Time Signature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.timeSignature.displayName)
                        .font(.title3)
                }
                
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatDuration(analysis.totalDuration))
                        .font(.title3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    ContentView()
}
