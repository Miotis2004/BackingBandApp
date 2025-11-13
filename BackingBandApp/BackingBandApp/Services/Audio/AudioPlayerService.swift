//
//  AudioPlayerService.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var audioInfo: AudioFileInfo?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    // MARK: - Audio File Info
    struct AudioFileInfo {
        let fileName: String
        let fileSize: Int64
        let duration: TimeInterval
        let sampleRate: Double
        let channels: Int
        let format: String
        
        var fileSizeString: String {
            ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
        
        var durationString: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Load Audio File
    func loadAudioFile(url: URL) throws {
        // Stop current playback
        stop()
        
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Create audio player
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        // Get audio file info
        if let player = audioPlayer {
            duration = player.duration
            
            // Get file attributes
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Get audio format info
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            
            audioInfo = AudioFileInfo(
                fileName: url.lastPathComponent,
                fileSize: fileSize,
                duration: player.duration,
                sampleRate: format.sampleRate,
                channels: Int(format.channelCount),
                format: url.pathExtension.uppercased()
            )
        }
        
        currentTime = 0
    }
    
    // MARK: - Playback Controls
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = self.audioPlayer?.currentTime ?? 0
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Cleanup
    deinit {
        // Clean up directly without calling stop() to avoid main actor issues
        timer?.invalidate()
        audioPlayer?.stop()
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.stopTimer()
        }
    }
}
