//
//  AudioErrors.swift
//  BackingBandApp
//
//  Created by Ronald Joubert on 11/14/25.
//

import Foundation

// MARK: - Rendering Errors
enum RenderError: LocalizedError {
    case invalidDuration
    case bufferCreationFailed
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Invalid audio duration"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .renderingFailed:
            return "Audio rendering failed"
        }
    }
}


