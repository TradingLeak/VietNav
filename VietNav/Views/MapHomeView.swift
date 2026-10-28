//
//  MapHomeView.swift
//  VietNav
//  Offline OSM map with speedmap overlays
//

import SwiftUI
import MapKit

struct MapHomeView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var loc = LocationService.shared
    @StateObject private var parser = SpeedmapParser.shared
    @State private var cameraPosition: MapCameraPosition = .userLocation(follows: .never)
    @State private var showingWarnings = false

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(parser.cameras) { cam in
                        Marker(cam.type.rawValue, coordinate: cam.coordinate)
                            .tint(Color(cam.type.color))
                    }
                    ForEach(parser.signs) { sign in
                        Marker(sign.text ?? "Biển báo", coordinate: sign.coordinate)
                            .tint(.blue)
                    }
                    if let route = app.currentRoute {
                        MapPolyline(coordinates: route.polyline)
                            .stroke(app.theme.primary, lineWidth: 4)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .onChange(of: loc.location) { _, new in
                    if let loc = new, cameraPosition == .userLocation(follows: .never) {
                        cameraPosition = .camera(MapCamera(centerCoordinate: loc.coordinate,
                                                           distance: 1200,
                                                           heading: loc.course >= 0 ? loc.course : 0,
                                                           pitch: 60))
                    }
                }
            }

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("VietNav").font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.linearGradient(colors: [app.theme.primary, app.theme.secondary], startPoint: .leading, endPoint: .trailing))
                        Text("Bản đồ ngoại tuyến • OpenStreetMap").font(.footnote).foregroundStyle(app.theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        app.showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(app.theme.primary)
                            .padding(12)
                            .background(app.theme.glass)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(app.theme.border, lineWidth: 1))
                    }
                }
                .padding()

                Spacer()

                if showingWarnings {
                    WarningBubbleView()
                        .padding(.bottom, 80)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Button {
                        showingWarnings.toggle()
                    } label: {
                        Label("Cảnh báo", systemImage: "exclamationmark.triangle.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(app.theme.text)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(app.theme.glass)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(app.theme.border, lineWidth: 1))
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            parser.loadAll()
            loc.requestPermission()
        }
    }
}

struct WarningBubbleView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var warning = WarningService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(warning.activeWarnings.prefix(3)) { w in
                HStack(spacing: 10) {
                    Image(systemName: w.type.icon)
                        .foregroundStyle(Color(w.type.color))
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.title).font(.callout.weight(.semibold)).foregroundStyle(app.theme.text)
                        if let sub = w.subtitle {
                            Text(sub).font(.caption2).foregroundStyle(app.theme.textSecondary)
                        }
                    }
                    Spacer()
                    Text(formatDistance(w.distance)).font(.caption2).foregroundStyle(app.theme.textSecondary)
                }
                .padding(10)
                .background(app.theme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(w.type.color).opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color(w.type.color).opacity(0.25), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
        .background(app.theme.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }

    func formatDistance(_ d: CLLocationDistance) -> String {
        if d < 1000 { return "\(Int(d)) m" }
        return String(format: "%.1f km", d / 1000)
    }
}
