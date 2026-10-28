//
//  RootView.swift
//  VietNav
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var loc = LocationService.shared

    var body: some View {
        ZStack {
            Theme.spaceX.background.ignoresSafeArea()

            if app.isNavigating {
                NavigationDashboardView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                MapHomeView()
                    .transition(.opacity)
            }

            if app.showSettings {
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(100)
            }

            VStack {
                Spacer()
                if !app.isNavigating {
                    HStack(spacing: 16) {
                        NeumorphicButton(icon: "magnifyingglass", label: "Tìm kiếm") {
                            // search
                        }
                        NeumorphicButton(icon: "location.north.line", label: "Vị trí") {
                            loc.start()
                        }
                        PrimaryButton(icon: "arrow.right.circle.fill", label: "Điều hướng") {
                            // start navigation demo
                            let route = Route(id: UUID(),
                                              name: "Nhà tại → Trung tâm",
                                              distance: 5400,
                                              expectedTravelTime: 600,
                                              legs: [Leg(id: UUID(),
                                                         distance: 5400,
                                                         expectedTravelTime: 600,
                                                         steps: [Step(id: UUID(),
                                                                          instruction: "Rẽ phải vào Lê Lợi",
                                                                          distance: 120,
                                                                          maneuver: .turnRight,
                                                                          polyline: [])],
                                                         startCoordinate: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.6657),
                                                         endCoordinate: CLLocationCoordinate2D(latitude: 10.7836, longitude: 106.6682))],
                                              polyline: [])
                            app.startNavigation(route)
                        }
                    }
                    .padding()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.isNavigating)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.showSettings)
    }
}
