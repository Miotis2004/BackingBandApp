//
//  SettingsView.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultGenre") private var defaultGenre = Genre.rock.rawValue
    @AppStorage("audioQuality") private var audioQuality = AudioQuality.high.rawValue
    
    var body: some View {
        Form {
            Section("Defaults") {
                Picker("Default Genre", selection: $defaultGenre) {
                    ForEach(Genre.allCases, id: \.rawValue) { genre in
                        Text(genre.displayName).tag(genre.rawValue)
                    }
                }
                
                Picker("Audio Quality", selection: $audioQuality) {
                    ForEach(AudioQuality.allCases, id: \.rawValue) { quality in
                        Text(quality.displayName).tag(quality.rawValue)
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .padding()
    }
}

enum AudioQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var sampleRate: Double {
        switch self {
        case .low: return 22050
        case .medium: return 44100
        case .high: return 48000
        }
    }
}

#Preview {
    SettingsView()
}
