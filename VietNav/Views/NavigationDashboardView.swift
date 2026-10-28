//
//  NavigationDashboardView.swift
//  VietNav
//  Turn-by-turn navigation dashboard (SpaceX style)
//

import SwiftUI

struct NavigationDashboardView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var warning = WarningService.shared

    var body: some View {
        ZStack {
            Theme.spaceX.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header HUD
                HUDHeaderView()

                Spacer(minLength: 0)

                // Maneuver banner
                ManeuverBannerView()

                Spacer(minLength: 0)

                // Speed panel
                SpeedPanelView()

                // Warning pills
                WarningPillsView()

                // Bottom controls
                BottomControlView()
            }
            .padding()
        }
    }
}

struct HUDHeaderView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TƯY ĐƯỜNG").font(.caption2.weight(.bold)).foregroundStyle(app.theme.textSecondary)
                Text(app.nextInstruction).font(.title3.weight(.semibold)).foregroundStyle(app.theme.primary)
            }
            Spacer()
            if let eta = app.eta {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ĐẾN HẠN").font(.caption2.weight(.bold)).foregroundStyle(app.theme.textSecondary)
                    Text(eta, style: .time).font(.title2.weight(.bold)).foregroundStyle(app.theme.text)
                }
            }
            Button {
                app.stopNavigation()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(app.theme.danger)
                    .padding(10)
                    .background(app.theme.danger.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(app.theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(app.theme.border, lineWidth: 1))
    }
}

struct ManeuverBannerView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: app.currentRoute?.legs.flatMap({ $0.steps }).first?.maneuver.icon ?? "arrow.up")
                .font(.system(size: 56))
                .foregroundStyle(app.theme.secondary)
                .frame(width: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.nextInstruction).font(.title2.weight(.bold)).foregroundStyle(app.theme.text)
                Text(app.distanceToNext < 1000 ? "\(Int(app.distanceToNext)) m" : String(format: "%.1f km", app.distanceToNext/1000))
                    .font(.subheadline).foregroundStyle(app.theme.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(app.theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(app.theme.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
    }
}

struct SpeedPanelView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var loc = LocationService.shared
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TỐC ĐỘ").font(.caption2.weight(.bold)).foregroundStyle(app.theme.textSecondary)
                Text(loc.location.map { String(format: "%.0f", $0.speed * 3.6) } ?? "--")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(app.isSpeeding ? app.theme.danger : app.theme.primary)
                Text("km/h").font(.caption).foregroundStyle(app.theme.textSecondary)
            }
            Spacer()
            if let limit = app.speedLimit {
                VStack(alignment: .center, spacing: 2) {
                    Text("GIỚI HẠN").font(.caption2.weight(.bold)).foregroundStyle(app.theme.textSecondary)
                    Text("\(Int(limit))").font(.system(size: 48, weight: .bold)).foregroundStyle(app.theme.text)
                    Text("km/h").font(.caption).foregroundStyle(app.theme.textSecondary)
                }
                .frame(width: 110)
                .background(app.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(app.theme.border, lineWidth: 1))
            }
        }
        .padding()
        .background(app.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(app.theme.border, lineWidth: 1))
    }
}

struct WarningPillsView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var warning = WarningService.shared
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(warning.activeWarnings) { w in
                    HStack(spacing: 8) {
                        Image(systemName: w.type.icon)
                            .foregroundStyle(Color(w.type.color))
                            .font(.caption)
                        Text(w.title).font(.caption.weight(.semibold)).foregroundStyle(app.theme.text)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(w.type.color).opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(w.type.color).opacity(0.4), lineWidth: 1))
                }
                if warning.activeWarnings.isEmpty {
                    Text("Không có cảnh báo").font(.caption).foregroundStyle(app.theme.textSecondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct BottomControlView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack(spacing: 16) {
            SecondaryButton(icon: "minus.magnifyingglass", label: "Phóng to")
            Spacer()
            PrimaryButton(icon: "speaker.wave.2.fill", label: "Giọng nói")
            Spacer()
            SecondaryButton(icon: "plus.magnifyingglass", label: "Thu nhỏ")
        }
        .padding()
        .background(app.theme.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(app.theme.border, lineWidth: 1))
    }
}
