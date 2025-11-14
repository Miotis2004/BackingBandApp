import Foundation
import AVFoundation
import Combine

@MainActor
class StemPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var stemCollection: StemCollection?
    private var timer: Timer?
    
    // MARK: - Load Stems
    func loadStems(_ stemCollection: StemCollection) {
        stop()
        
        self.stemCollection = stemCollection
        
        // Create player node for each stem
        playerNodes.removeAll()
        
        for stem in stemCollection.stems {
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            
            // Connect to mixer
            let mixer = engine.mainMixerNode
            engine.connect(playerNode, to: mixer, format: stem.buffer.format)
            
            playerNodes.append(playerNode)
        }
        
        // Calculate duration (longest stem)
        duration = stemCollection.stems.map {
            TimeInterval($0.buffer.frameLength) / $0.buffer.format.sampleRate
        }.max() ?? 0
        
        // Start engine
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    func play() {
        guard let stemCollection = stemCollection, !stemCollection.stems.isEmpty, !isPlaying else { return }
        
        // Schedule buffers for all stems
        for (index, stem) in stemCollection.stems.enumerated() {
            guard index < playerNodes.count else { continue }
            
            let playerNode = playerNodes[index]
            let effectiveVolume = stemCollection.effectiveLevel(for: stem) * stemCollection.masterLevel
            
            playerNode.volume = effectiveVolume
            
            // Schedule the buffer
            playerNode.scheduleBuffer(stem.buffer, at: nil, options: .interrupts)
        }
        
        // Start all player nodes simultaneously
        for playerNode in playerNodes {
            playerNode.play()
        }
        
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        for playerNode in playerNodes {
            playerNode.pause()
        }
        
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        for playerNode in playerNodes {
            playerNode.stop()
        }
        
        currentTime = 0
        isPlaying = false
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        stop()
        currentTime = time
        if isPlaying {
            play()
        }
    }
    
    // MARK: - Volume Updates
    func updateStemVolumes(_ stemCollection: StemCollection) {
        for (index, stem) in stemCollection.stems.enumerated() {
            guard index < playerNodes.count else { continue }
            let effectiveVolume = stemCollection.effectiveLevel(for: stem) * stemCollection.masterLevel
            playerNodes[index].volume = effectiveVolume
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let firstNode = self.playerNodes.first else { return }
            
            Task { @MainActor in
                if let nodeTime = firstNode.lastRenderTime,
                   let playerTime = firstNode.playerTime(forNodeTime: nodeTime) {
                    self.currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        timer?.invalidate()
        for node in playerNodes {
            node.stop()
        }
        engine.stop()
    }
}
