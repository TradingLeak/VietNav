//
//  VietNavApp.swift
//  VietNav
//
//  Main entry point for the VietNav iOS navigation app.
//  Designed by: Software Engineer (iOS)
//  Style: SpaceX-inspired futuristic dark theme
//

import SwiftUI

@main
struct VietNavApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppState.shared)
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Bootstrap services
        _ = SpeedmapParser.shared
        _ = OSMMapService.shared
        _ = AIRoutingService.shared
        _ = LocationService.shared
        return true
    }
}
