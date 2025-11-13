//
//  BackingBandAppApp.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/13/25.
//

import SwiftUI

@main
struct BackingBandGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Audio File...") {
                    // We'll handle this via notification or shared state
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandMenu("Audio") {
                Button("Generate Backing Band") {
                    NotificationCenter.default.post(name: .generate, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)
                
                Divider()
                
                Button("Export...") {
                    NotificationCenter.default.post(name: .export, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// Notification names
extension Notification.Name {
    static let openFile = Notification.Name("openFile")
    static let generate = Notification.Name("generate")
    static let export = Notification.Name("export")
}
