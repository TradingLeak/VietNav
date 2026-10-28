//
//  AppState.swift
//  VietNav
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isNavigating = false
    @Published var currentRoute: Route?
    @Published var currentStepIndex = 0
    @Published var currentSpeed: Double = 0 // km/h
    @Published var speedLimit: Double? // km/h
    @Published var isSpeeding = false
    @Published var nextInstruction: String = ""
    @Published var distanceToNext: CLLocationDistance = 0
    @Published var eta: Date?
    @Published var showSidePanel = false
    @Published var showSettings = false
    @Published var theme = Theme.spaceX

    private init() {}

    func startNavigation(_ route: Route) {
        self.currentRoute = route
        self.isNavigating = true
        self.currentStepIndex = 0
        self.nextInstruction = route.legs.first?.steps.first?.instruction ?? "Bắt đầu di chuyển"
        self.distanceToNext = route.legs.first?.steps.first?.distance ?? 0
    }

    func stopNavigation() {
        self.isNavigating = false
        self.currentRoute = nil
        self.currentStepIndex = 0
    }
}

struct Route: Identifiable, Codable {
    let id: UUID
    var name: String
    var distance: CLLocationDistance // meters
    var expectedTravelTime: TimeInterval // seconds
    var legs: [Leg]
    var polyline: [CLLocationCoordinate2D]
    var aiOptimized: Bool = false
}

struct Leg: Identifiable, Codable {
    let id: UUID
    var distance: CLLocationDistance
    var expectedTravelTime: TimeInterval
    var steps: [Step]
    var startCoordinate: CLLocationCoordinate2D
    var endCoordinate: CLLocationCoordinate2D
}

struct Step: Identifiable, Codable {
    let id: UUID
    var instruction: String
    var distance: CLLocationDistance
    var maneuver: Maneuver
    var polyline: [CLLocationCoordinate2D]
}

enum Maneuver: String, Codable, CaseIterable {
    case depart, arrive, turnLeft, turnRight, slightLeft, slightRight, sharpLeft, sharpRight, uTurn, continueStraight, roundabout
    var icon: String {
        switch self {
        case .depart: return "play.fill"
        case .arrive: return "flag.fill"
        case .turnLeft: return "arrow.turn.up.left"
        case .turnRight: return "arrow.turn.up.right"
        case .slightLeft: return "arrow.turn.up.left"
        case .slightRight: return "arrow.turn.up.right"
        case .sharpLeft: return "arrow.uturn.left"
        case .sharpRight: return "arrow.uturn.right"
        case .uTurn: return "arrow.uturn.left"
        case .continueStraight: return "arrow.up"
        case .roundabout: return "arrow.triangle.branch"
        }
    }
}

// MARK: - Theme
struct Theme: Equatable {
    static let spaceX = Theme(
        background: Color(hex: "#050507"),
        surface: Color(hex: "#0e0e14"),
        surfaceElevated: Color(hex: "#151520"),
        primary: Color(hex: "#00ff9d"),
        secondary: Color(hex: "#00b4d8"),
        accent: Color(hex: "#ff0055"),
        text: Color(hex: "#ffffff"),
        textSecondary: Color(hex: "#9aa5b1"),
        danger: Color(hex: "#ff3b30"),
        warning: Color(hex: "#ffcc00"),
        glass: Color.white.opacity(0.06),
        border: Color.white.opacity(0.12)
    )
    var background: Color
    var surface: Color
    var surfaceElevated: Color
    var primary: Color
    var secondary: Color
    var accent: Color
    var text: Color
    var textSecondary: Color
    var danger: Color
    var warning: Color
    var glass: Color
    var border: Color
}

import SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        case 3:
            r = Double((int >> 8) & 0xF) / 15
            g = Double((int >> 4) & 0xF) / 15
            b = Double(int & 0xF) / 15
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, opacity: 1)
    }
}
