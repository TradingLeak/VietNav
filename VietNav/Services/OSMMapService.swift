//
//  OSMMapService.swift
//  VietNav
//  Offline OpenStreetMap tile service using tiles.bin + index.bin
//

import Foundation
import MapKit
import CoreLocation

final class OSMMapService {
    static let shared = OSMMapService()
    private init() {}

    /// Tile coordinate for a given location & zoom
    func tileCoord(for coordinate: CLLocationCoordinate2D, zoom: Int) -> (x: Int, y: Int) {
        let latRad = coordinate.latitude * .pi / 180
        let n = 1 << zoom
        let x = Int((coordinate.longitude + 180.0) / 360.0 * Double(n))
        let y = Int((1.0 - log(tan(latRad) + 1 / cos(latRad)) / .pi) / 2.0 * Double(n))
        return (x, y)
    }

    /// Look up tile bytes from tiles.bin via index.bin (spatial grid)
    func tileData(z: Int, x: Int, y: Int) -> Data? {
        guard let indexURL = Bundle.main.url(forResource: "index", withExtension: "bin"),
              let tilesURL = Bundle.main.url(forResource: "tiles", withExtension: "bin") else { return nil }
        do {
            let indexData = try Data(contentsOf: indexURL)
            let tilesData = try Data(contentsOf: tilesURL)
            // index.bin is a spatial grid: offset + length per tile
            let entrySize = 16 // 8 offset + 8 length
            let key = "\(z)/\(x)/\(y)"
            let hash = abs(key.hashValue) % (indexData.count / entrySize)
            let off = hash * entrySize
            guard off + entrySize <= indexData.count else { return nil }
            let offset = indexData.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off).assumingMemoryBound(to: Int64.self).pointee
            }
            let length = indexData.withUnsafeBytes { ptr in
                ptr.baseAddress!.advanced(by: off + 8).assumingMemoryBound(to: Int64.self).pointee
            }
            guard offset >= 0, length > 0, Int(offset) + Int(length) <= tilesData.count else { return nil }
            return tilesData.subdata(in: Int(offset)..<Int(offset) + Int(length))
        } catch {
            return nil
        }
    }
}
