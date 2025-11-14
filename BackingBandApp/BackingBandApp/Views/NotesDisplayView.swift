//
//  NotesDisplayView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

struct NotesDisplayView: View {
    let track: MIDITrack
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Notes: \(track.notes.count)")
                .font(.headline)
            
            if track.notes.isEmpty {
                Text("No notes detected")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(track.notes.prefix(50)) { note in
                            NoteRowView(note: note)
                        }
                        
                        if track.notes.count > 50 {
                            Text("... and \(track.notes.count - 50) more notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NoteRowView: View {
    let note: MIDINote
    
    var body: some View {
        HStack(spacing: 12) {
            // Note name
            Text(noteName(for: note.pitch))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 40, alignment: .leading)
            
            // Time
            Text(formatTime(note.startTime))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Duration bar
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: min(geometry.size.width, CGFloat(note.duration * 100)))
            }
            .frame(height: 8)
            
            // Duration text
            Text(String(format: "%.2fs", note.duration))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Velocity
            Text("\(note.velocity)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(4)
    }
    
    private func noteName(for pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = noteNames[Int(pitch) % 12]
        return "\(note)\(octave)"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        String(format: "%.2fs", time)
    }
}

#Preview {
    NotesDisplayView(track: MIDITrack(
        name: "Test",
        notes: [
            MIDINote(pitch: 60, velocity: 100, startTime: 0.0, duration: 0.5),
            MIDINote(pitch: 64, velocity: 90, startTime: 0.5, duration: 0.5),
            MIDINote(pitch: 67, velocity: 95, startTime: 1.0, duration: 0.5),
        ]
    ))
    .padding()
}
