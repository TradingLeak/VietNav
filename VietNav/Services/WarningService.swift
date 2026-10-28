//
//  WarningService.swift
//  VietNav
//  Real-time sign & camera warnings during navigation
//

import Foundation
import Combine
import CoreLocation

final class WarningService: ObservableObject {
    static let shared = WarningService()
    private let parser = SpeedmapParser.shared
    @Published var activeWarnings: [Warning] = []
    @Published var speedLimitExceeded = false
    private var timer: Timer?

    struct Warning: Identifiable {
        let id = UUID()
        var type: WarningType
        var title: String
        var subtitle: String?
        var distance: CLLocationDistance
        var coordinate: CLLocationCoordinate2D
    }

    enum WarningType: String {
        case camera, sign, speeding, upcomingTurn
        var icon: String {
            switch self {
            case .camera: return "camera.fill"
            case .sign: return "signpost.fill"
            case .speeding: return "gauge.with.dots.needle.33percent"
            case .upcomingTurn: return "arrow.turn.up.right"
            }
        }
        var color: String {
            switch self {
            case .camera: return "#ff3b30"
            case .sign: return "#00b4d8"
            case .speeding: return "#ff0055"
            case .upcomingTurn: return "#00ff9d"
            }
        }
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func evaluate() {
        guard let loc = LocationService.shared.location else { return }
        let coord = loc.coordinate
        let speed = loc.speed * 3.6 // m/s -> km/h

        var warnings: [Warning] = []

        // Cameras & signs nearby
        let (cams, signs) = parser.warningsNear(coordinate: coord, radius: 500)
        for c in cams {
            warnings.append(Warning(type: .camera,
                                    title: "Camera \(c.type.rawValue)",
                                    subtitle: c.speedLimit.map { "Giới hạn \(Int($0)) km/h" },
                                    distance: coord.distance(to: c.coordinate),
                                    coordinate: c.coordinate))
        }
        for s in signs {
            warnings.append(Warning(type: .sign,
                                    title: s.text ?? "Biển báo",
                                    subtitle: nil,
                                    distance: coord.distance(to: s.coordinate),
                                    coordinate: s.coordinate))
        }

        // Speeding check
        if let limit = AppState.shared.speedLimit, speed > limit + 2 {
            warnings.append(Warning(type: .speeding,
                                    title: "Vượt tốc độ",
                                    subtitle: "\(Int(speed)) km/h / \(Int(limit)) km/h",
                                    distance: 0,
                                    coordinate: coord))
            speedLimitExceeded = true
        } else {
            speedLimitExceeded = false
        }

        // Upcoming turn
        if let route = AppState.shared.currentRoute,
           AppState.shared.currentStepIndex < route.legs.flatMap({ $0.steps }).count {
            let step = route.legs.flatMap({ $0.steps })[AppState.shared.currentStepIndex]
            if step.distance < 200 {
                warnings.append(Warning(type: .upcomingTurn,
                                        title: step.instruction,
                                        subtitle: "\(Int(step.distance)) m",
                                        distance: step.distance,
                                        coordinate: coord))
            }
        }

        self.activeWarnings = warnings.sorted { $0.distance < $1.distance }
    }
}
