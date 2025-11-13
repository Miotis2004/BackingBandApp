//
//  AudioPlayerView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var player: AudioPlayerService
    let audioURL: URL
    
    var body: some View {
        VStack(spacing: 16) {
            // File Info
            if let info = player.audioInfo {
                AudioInfoView(info: info)
            }
            
            // Waveform
            WaveformView(audioURL: audioURL)
                .padding(.horizontal)
            
            // Progress Slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    in: 0...max(player.duration, 0.1)
                )
                .disabled(player.duration == 0)
                
                HStack {
                    Text(formatTime(player.currentTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formatTime(player.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal)
            
            // Playback Controls
            HStack(spacing: 20) {
                Button(action: { player.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(player.duration == 0)
                
                Button(action: {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(player.duration == 0)
                .keyboardShortcut(.space, modifiers: [])
            }
            .padding(.bottom, 8)
        }
        .padding()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AudioInfoView: View {
    let info: AudioPlayerService.AudioFileInfo
    
    var body: some View {
        VStack(spacing: 8) {
            Text(info.fileName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            
            HStack(spacing: 20) {
                InfoItem(label: "Duration", value: info.durationString)
                InfoItem(label: "Size", value: info.fileSizeString)
                InfoItem(label: "Sample Rate", value: "\(Int(info.sampleRate)) Hz")
                InfoItem(label: "Channels", value: "\(info.channels)")
                InfoItem(label: "Format", value: info.format)
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}
