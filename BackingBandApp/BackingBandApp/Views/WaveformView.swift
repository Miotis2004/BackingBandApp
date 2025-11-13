//
//  WaveformView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI
import AVFoundation

struct WaveformView: View {
    let audioURL: URL
    @State private var samples: [Float] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Analyzing audio...")
            } else if samples.isEmpty {
                Text("No waveform data")
                    .foregroundStyle(.secondary)
            } else {
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let midHeight = height / 2
                        
                        // Draw waveform
                        let step = width / CGFloat(samples.count)
                        
                        for (index, sample) in samples.enumerated() {
                            let x = CGFloat(index) * step
                            let amplitude = CGFloat(sample) * midHeight
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: midHeight))
                            }
                            
                            path.addLine(to: CGPoint(x: x, y: midHeight - amplitude))
                            path.addLine(to: CGPoint(x: x, y: midHeight + amplitude))
                        }
                    }
                    .fill(Color.accentColor.opacity(0.7))
                }
            }
        }
        .frame(height: 100)
        .task {
            await loadWaveform()
        }
    }
    
    private func loadWaveform() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let file = try AVAudioFile(forReading: audioURL)
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return
            }
            
            try file.read(into: buffer)
            
            guard let channelData = buffer.floatChannelData else {
                return
            }
            
            let channelDataValue = channelData.pointee
            let channelDataArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(frameCount)))
            
            // Downsample to ~1000 points for display
            let targetSamples = 1000
            let sampleStride = max(1, channelDataArray.count / targetSamples)
            
            var downsampled: [Float] = []
            for index in stride(from: 0, to: channelDataArray.count, by: sampleStride) {
                let endIndex = min(index + sampleStride, channelDataArray.count)
                let slice = channelDataArray[index..<endIndex]
                let average = slice.reduce(0, { $0 + abs($1) }) / Float(slice.count)
                downsampled.append(average)
            }
            
            samples = downsampled
            
        } catch {
            print("Error loading waveform: \(error)")
        }
    }
}

