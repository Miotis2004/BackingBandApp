//
//  StemMixerView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

struct StemMixerView: View {
    @ObservedObject var stemCollection: StemCollection
    @ObservedObject var stemPlayer: StemPlayerService  // Change this
    let onExportMixed: () -> Void
    let onExportStems: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Mix")
                .font(.headline)
            
            // Master fader
            VStack(spacing: 8) {
                HStack {
                    Text("Master")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: $stemCollection.masterLevel, in: 0...2)
                        .frame(maxWidth: .infinity)
                        .onChange(of: stemCollection.masterLevel) { _, _ in
                            stemPlayer.updateStemVolumes(stemCollection)
                        }
                    
                    Text(String(format: "%.1f", stemCollection.masterLevel))
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                
                Divider()
            }
            
            // Individual stems
            ForEach(stemCollection.stems) { stem in
                StemChannelView(stem: stem, stemCollection: stemCollection, stemPlayer: stemPlayer)
            }
            
            Divider()
            
            // Playback and export controls
            HStack(spacing: 12) {
                Button(action: {
                    if stemPlayer.isPlaying {
                        stemPlayer.pause()
                    } else {
                        stemPlayer.play()
                    }
                }) {
                    Image(systemName: stemPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                }
                .help("Preview mix")
                
                Button(action: { stemPlayer.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .help("Stop")
                
                Spacer()
                
                Button("Export Mixed") {
                    onExportMixed()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Export Stems") {
                    onExportStems()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StemChannelView: View {
    @ObservedObject var stem: AudioStem
    @ObservedObject var stemCollection: StemCollection
    @ObservedObject var stemPlayer: StemPlayerService
    
    var body: some View {
        HStack(spacing: 12) {
            // Stem name
            Text(stem.name)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
            
            // Mute button
            Button(action: {
                stem.isMuted.toggle()
                stemPlayer.updateStemVolumes(stemCollection)
            }) {
                Image(systemName: stem.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(stem.isMuted ? .red : .primary)
            }
            .buttonStyle(.plain)
            .help(stem.isMuted ? "Unmute" : "Mute")
            
            // Solo button
            Button(action: {
                stem.isSoloed.toggle()
                stemPlayer.updateStemVolumes(stemCollection)
            }) {
                Text("S")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(stem.isSoloed ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(stem.isSoloed ? "Unsolo" : "Solo")
            
            // Level slider
            Slider(value: $stem.level, in: 0...2)
                .frame(maxWidth: .infinity)
                .disabled(stem.isMuted)
                .onChange(of: stem.level) { _, _ in
                    stemPlayer.updateStemVolumes(stemCollection)
                }
            
            // Level display
            Text(String(format: "%.1f", stem.level))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(stem.isMuted ? .secondary : .primary)
        }
        .opacity(stem.isMuted ? 0.5 : 1.0)
    }
}

//#Preview {
//    StemMixerView(
//        stemCollection: StemCollection(), stemPlayer: <#StemPlayerService#>,
//        onExportMixed: {},
//        onExportStems: {},
//        onPlayPause: {},
//        isPlaying: .constant(false)
//    )
//    .padding()
//}
