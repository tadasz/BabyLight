//
//  LightColor.swift
//  Baby Light
//

import SwiftUI

/// Represents a light color preset optimized for baby sleep
/// Red and warm amber lights minimize melatonin disruption
struct LightColor: Identifiable, Equatable {
    let id: String
    let color: Color
    let name: String
    let description: String
    
    /// Initialize from hex color string
    init(id: String, hex: String, name: String, description: String) {
        self.id = id
        self.color = Color(hex: hex)
        self.name = name
        self.description = description
    }
    
    /// Preset colors matching the web app
    static let presets: [LightColor] = [
        LightColor(id: "deep-red", hex: "#FF0000", name: "Deep Red", description: "Best for sleep"),
        LightColor(id: "amber", hex: "#FF4500", name: "Amber", description: "Warm & soothing"),
        LightColor(id: "candle", hex: "#FF8C00", name: "Candle", description: "Soft orange"),
        LightColor(id: "dim-white", hex: "#F5DEB3", name: "Wheat", description: "If you need more light")
    ]
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 6: // RGB (24-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1.0; g = 0.0; b = 0.0 // Fallback to red
        }
        
        self.init(red: r, green: g, blue: b)
    }
}
