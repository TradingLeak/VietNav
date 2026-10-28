//
//  AIRoutingService.swift
//  VietNav
//  AI smart routing via ckey.vn custom model
//

import Foundation
import Combine
import CoreLocation
import Security

enum AIProviderError: Error, LocalizedError {
    case invalidURL, noData, decodingFailed, serverError(Int), cancelled, missingAPIKey
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL không hợp lệ"
        case .noData: return "Không có dữ liệu phản hồi"
        case .decodingFailed: return "Lỗi giải mã phản hồi"
        case .serverError(let code): return "Lỗi máy chủ: \(code)"
        case .cancelled: return "Yêu cầu đã bị hủy"
        case .missingAPIKey: return "Thiếu API key"
        }
    }
}

struct AIRequest: Codable {
    var origin: String // "lat,lng"
    var destination: String // "lat,lng"
    var waypoints: [String] = []
    var model: String
    var language: String = "vi"
    var avoidTolls: Bool = false
    var avoidHighways: Bool = false
    var traffic: Bool = true
}

struct AIResponse: Codable {
    var routes: [AIRoute]
    var modelUsed: String?
}

struct AIRoute: Codable {
    var summary: String
    var distanceMeters: Double
    var durationSeconds: Double
    var polyline: String // encoded polyline
    var steps: [AIStep]
}

struct AIStep: Codable {
    var instruction: String
    var distanceMeters: Double
    var durationSeconds: Double
}

final class AIRoutingService: ObservableObject {
    static let shared = AIRoutingService()

    @Published var baseURL: String = UserDefaults.standard.string(forKey: "ai_baseURL") ?? "https://ckey.vn"
    @Published var apiKey: String = KeychainHelper.shared.read(key: "ai_apiKey") ?? ""
    @Published var model: String = UserDefaults.standard.string(forKey: "ai_model") ?? "vietnav-custom"
    @Published var isComputing = false
    @Published var lastError: AIProviderError?

    private let session = URLSession.shared
    private var task: Task<Void, Never>?

    func computeRoute(origin: CLLocationCoordinate2D,
                      destination: CLLocationCoordinate2D,
                      waypoints: [CLLocationCoordinate2D] = []) async throws -> Route? {
        guard !apiKey.isEmpty else { throw AIProviderError.missingAPIKey }
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines) + "/route") else {
            throw AIProviderError.invalidURL
        }

        isComputing = true
        defer { isComputing = false }

        let req = AIRequest(
            origin: "\(origin.latitude),\(origin.longitude)",
            destination: "\(destination.latitude),\(destination.longitude)",
            waypoints: waypoints.map { "\($0.latitude),\($0.longitude)" },
            model: model
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(req)

        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw AIProviderError.serverError(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(AIResponse.self, from: data)
            return mapToRoute(decoded)
        } catch {
            if let err = error as? AIProviderError { lastError = err }
            throw error
        }
    }

    private func mapToRoute(_ resp: AIResponse) -> Route? {
        guard let first = resp.routes.first else { return nil }
        var coords: [CLLocationCoordinate2D] = []
        // decode simple polyline
        var index = first.polyline.startIndex
        var lat = 0.0, lng = 0.0
        while index < first.polyline.endIndex {
            // minimal decoder placeholder - real polyline decode here
            break
        }
        let leg = Leg(id: UUID(),
                      distance: first.distanceMeters,
                      expectedTravelTime: first.durationSeconds,
                      steps: first.steps.enumerated().map { i, s in
                          Step(id: UUID(),
                               instruction: s.instruction,
                               distance: s.distanceMeters,
                               maneuver: .continueStraight,
                               polyline: [])
                      },
                      startCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                      endCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        return Route(id: UUID(),
                     name: first.summary,
                     distance: first.distanceMeters,
                     expectedTravelTime: first.durationSeconds,
                     legs: [leg],
                     polyline: coords,
                     aiOptimized: true)
    }

    func saveSettings() {
        UserDefaults.standard.set(baseURL, forKey: "ai_baseURL")
        UserDefaults.standard.set(model, forKey: "ai_model")
        if !apiKey.isEmpty { KeychainHelper.shared.write(key: "ai_apiKey", value: apiKey) }
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    func write(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    func read(key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
