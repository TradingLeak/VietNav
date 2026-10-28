//
//  SpeedmapParser.swift
//  VietNav
//  Parses the 7 offline .bin files from VietHUD speedmap:
//  cameras.bin, signs.bin, tiles.bin, index.bin, metadata.bin,
//  names.bin, seg_names.bin
//

import Foundation
import Combine
import CoreLocation

// MARK: - Speedmap data models
struct SpeedCamera: Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var type: CameraType
    var speedLimit: Double?
    var direction: Double? // degrees
}

enum CameraType: String, Codable, CaseIterable {
    case fixed, mobile, redLight, average, unknown
    var icon: String {
        switch self {
        case .fixed: return "camera.fill"
        case .mobile: return "camera.aperture"
        case .redLight: return "lighttrafficlight.fill"
        case .average: return "gauge.with.dots.needle.33percent"
        case .unknown: return "exclamationmark.triangle.fill"
        }
    }
    var color: String {
        switch self {
        case .fixed, .average: return "#ff3b30"
        case .mobile: return "#ff9500"
        case .redLight: return "#ff0055"
        case .unknown: return "#9aa5b1"
        }
    }
}

struct RoadSign: Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var type: SignType
    var text: String?
    var distanceAhead: CLLocationDistance?
}

enum SignType: String, Codable, CaseIterable {
    case urbanArea, noOvertaking, toll, speedLimit, warning, info, unknown
    var icon: String {
        switch self {
        case .urbanArea: return "building.2.fill"
        case .noOvertaking: return "car.fill"
        case .toll: return "creditcard.fill"
        case .speedLimit: return "speedometer"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .unknown: return "circle.fill"
        }
    }
}

struct StreetName: Codable {
    var id: Int
    var name: String
}

struct SegmentName: Codable {
    var segmentId: Int
    var nameId: Int
}

// MARK: - Parser
final class SpeedmapParser {
    static let shared = SpeedmapParser()
    private init() {}

    @Published var cameras: [SpeedCamera] = []
    @Published var signs: [RoadSign] = []
    @Published var streetNames: [Int: StreetName] = [:]
    @Published var segmentNames: [Int: Int] = [:] // segmentId -> nameId
    @Published var metadata: [String: Any] = [:]
    @Published var isLoaded = false

    private let bundle = Bundle.main

    func loadAll() {
        let group = DispatchGroup()
        group.enter(); loadMetadata() { group.leave() }
        group.enter(); loadCameras() { group.leave() }
        group.enter(); loadSigns() { group.leave() }
        group.enter(); loadNames() { group.leave() }
        group.enter(); loadSegmentNames() { group.leave() }
        group.notify(queue: .main) {
            self.isLoaded = true
        }
    }

    // metadata.bin - small JSON config (coordinate frame & map config)
    private func loadMetadata(completion: @escaping () -> Void) {
        guard let url = bundle.url(forResource: "metadata", withExtension: "bin") else { completion(); return }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            self.metadata = json
        } catch {
            // fallback: raw config
            self.metadata = ["version": "2026.10", "frame": "WGS84"]
        }
        completion()
    }

    // cameras.bin
    private func loadCameras(completion: @escaping () -> Void) {
        guard let url = bundle.url(forResource: "cameras", withExtension: "bin") else { completion(); return }
        do {
            let data = try Data(contentsOf: url)
            // Try JSON first (modern export), fall back to binary reader
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                self.cameras = json.compactMap { parseCamera(dict: $0) }
            } else {
                self.cameras = parseBinaryCameras(data)
            }
        } catch {
            self.cameras = []
        }
        completion()
    }

    // signs.bin
    private func loadSigns(completion: @escaping () -> Void) {
        guard let url = bundle.url(forResource: "signs", withExtension: "bin") else { completion(); return }
        do {
            let data = try Data(contentsOf: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                self.signs = json.compactMap { parseSign(dict: $0) }
            } else {
                self.signs = parseBinarySigns(data)
            }
        } catch { self.signs = [] }
        completion()
    }

    // names.bin - street dictionary
    private func loadNames(completion: @escaping () -> Void) {
        guard let url = bundle.url(forResource: "names", withExtension: "bin") else { completion(); return }
        do {
            let data = try Data(contentsOf: url)
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var dict: [Int: StreetName] = [:]
                for item in arr {
                    if let id = item["id"] as? Int, let name = item["name"] as? String {
                        dict[id] = StreetName(id: id, name: name)
                    }
                }
                self.streetNames = dict
            }
        } catch { self.streetNames = [:] }
        completion()
    }

    // seg_names.bin - segment -> name mapping
    private func loadSegmentNames(completion: @escaping () -> Void) {
        guard let url = bundle.url(forResource: "seg_names", withExtension: "bin") else { completion(); return }
        do {
            let data = try Data(contentsOf: url)
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var dict: [Int: Int] = [:]
                for item in arr {
                    if let seg = item["segmentId"] as? Int, let nameId = item["nameId"] as? Int {
                        dict[seg] = nameId
                    }
                }
                self.segmentNames = dict
            }
        } catch { self.segmentNames = [:] }
        completion()
    }

    // Helpers
    private func parseCamera(dict: [String: Any]) -> SpeedCamera? {
        guard let lat = dict["lat"] as? Double, let lng = dict["lng"] as? Double else { return nil }
        let typeRaw = dict["type"] as? String ?? "fixed"
        return SpeedCamera(id: UUID(),
                           coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                           type: CameraType(rawValue: typeRaw) ?? .fixed,
                           speedLimit: dict["speedLimit"] as? Double,
                           direction: dict["direction"] as? Double)
    }

    private func parseSign(dict: [String: Any]) -> RoadSign? {
        guard let lat = dict["lat"] as? Double, let lng = dict["lng"] as? Double else { return nil }
        return RoadSign(id: UUID(),
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                        type: SignType(rawValue: dict["type"] as? String ?? "warning") ?? .warning,
                        text: dict["text"] as? String,
                        distanceAhead: dict["distanceAhead"] as? CLLocationDistance)
    }

    // Minimal binary fallbacks (offsets subject to VietHUD format version)
    private func parseBinaryCameras(_ data: Data) -> [SpeedCamera] {
        var out: [SpeedCamera] = []
        let count = min(data.count / 24, 5000)
        for i in 0..<count {
            let off = i * 24
            guard off + 24 <= data.count else { break }
            let lat = data.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off).assumingMemoryBound(to: Double.self).pointee
            }
            let lng = data.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off + 8).assumingMemoryBound(to: Double.self).pointee
            }
            out.append(SpeedCamera(id: UUID(),
                                   coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                   type: .fixed,
                                   speedLimit: nil,
                                   direction: nil))
        }
        return out
    }

    private func parseBinarySigns(_ data: Data) -> [RoadSign] {
        var out: [RoadSign] = []
        let count = min(data.count / 24, 5000)
        for i in 0..<count {
            let off = i * 24
            guard off + 24 <= data.count else { break }
            let lat = data.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off).assumingMemoryBound(to: Double.self).pointee
            }
            let lng = data.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off + 8).assumingMemoryBound(to: Double.self).pointee
            }
            out.append(RoadSign(id: UUID(),
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                type: .warning,
                                text: nil,
                                distanceAhead: nil))
        }
        return out
    }

    /// Warnings near current location (within radius meters)
    func warningsNear(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 300)
        -> (cameras: [SpeedCamera], signs: [RoadSign]) {
        let cameras = cameras.filter { $0.coordinate.distance(to: coordinate) <= radius }
        let signs = signs.filter { $0.coordinate.distance(to: coordinate) <= radius }
        return (cameras, signs)
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
