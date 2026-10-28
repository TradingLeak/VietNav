//
//  SettingsView.swift
//  VietNav
//  AI settings & custom model (ckey.vn)
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var ai = AIRoutingService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Theme.spaceX.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    header
                    section(title: "TRIÊN KHAI AI") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledTextField(title: "Base URL", text: $ai.baseURL, placeholder: "https://ckey.vn")
                            LabeledTextField(title: "Model tùy chỉnh", text: $ai.model, placeholder: "vietnav-custom")
                            LabeledSecureField(title: "API Key", text: .constant(ai.apiKey.isEmpty ? "••••••••" : ""), placeholder: "Nhập API key")
                                .disabled(true)
                            Button("Lưu cấu hình AI") {
                                ai.saveSettings()
                            }
                            .buttonStyle(SpaceXButtonStyle())
                            if let err = ai.lastError {
                                Text(err.localizedDescription).font(.caption2).foregroundStyle(app.theme.danger)
                            }
                        }
                    }
                    section(title: "DỮ LIỆU BẢN ĐỒ") {
                        SettingsRow(icon: "map.fill", title: "Tiles (mạng lưới đường)", subtitle: "tiles.bin • khoảng 235 MB")
                        SettingsRow(icon: "map.fill", title: "Chỉ mục không gian", subtitle: "index.bin")
                        SettingsRow(icon: "camera.fill", title: "Camera phạt nguội", subtitle: "cameras.bin")
                        SettingsRow(icon: "signpost.fill", title: "Biển báo", subtitle: "signs.bin")
                        SettingsRow(icon: "textformat", title: "Tên đường", subtitle: "names.bin, seg_names.bin")
                        SettingsRow(icon: "gear", title: "Cấu hình tọa độ", subtitle: "metadata.bin")
                    }
                    section(title: "NGUYÊN TẮC") {
                        SettingsRow(icon: "lock.shield", title: "Bảo mật", subtitle: "API key lưu trong Keychain")
                        SettingsRow(icon: "antenna.radiowaves.left.and.right", title: "Ngoại tuyến", subtitle: "Toàn bộ bản đồ chạy trên thiết bị")
                    }
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }

    var header: some View {
        HStack {
            Button {
                app.showSettings = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(app.theme.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("CÀI ĐẶT").font(.headline.weight(.black)).foregroundStyle(app.theme.text)
                Text("VietNav Premium").font(.caption2).foregroundStyle(app.theme.textSecondary)
            }
            Spacer()
        }
        .padding()
    }

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(app.theme.textSecondary)
            content()
        }
        .padding(16)
        .background(app.theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(app.theme.border, lineWidth: 1))
    }
}

struct LabeledTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(app.theme.textSecondary)
            TextField(placeholder, text: $text)
                .font(.body)
                .padding(12)
                .background(app.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(app.theme.border, lineWidth: 1))
                .foregroundStyle(app.theme.text)
        }
    }
}

struct LabeledSecureField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(app.theme.textSecondary)
            SecureField(placeholder, text: $text)
                .font(.body)
                .padding(12)
                .background(app.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(app.theme.border, lineWidth: 1))
                .foregroundStyle(app.theme.text)
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    var subtitle: String
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(app.theme.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium)).foregroundStyle(app.theme.text)
                Text(subtitle).font(.caption2).foregroundStyle(app.theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(app.theme.textSecondary)
        }
        .padding(12)
        .background(app.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(app.theme.border.opacity(0.5), lineWidth: 1))
    }
}

struct SpaceXButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    var icon: String
    var label: String
    var action: () -> Void
    @EnvironmentObject var app: AppState
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.callout)
                Text(label).font(.callout.weight(.semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(app.theme.primary)
            .clipShape(Capsule())
        }
    }
}

struct SecondaryButton: View {
    var icon: String
    var label: String
    @EnvironmentObject var app: AppState
    var body: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.callout)
                Text(label).font(.callout.weight(.semibold))
            }
            .foregroundStyle(app.theme.text)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(app.theme.glass)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(app.theme.border, lineWidth: 1))
        }
    }
}

struct NeumorphicButton: View {
    var icon: String
    var label: String
    var action: () -> Void
    @EnvironmentObject var app: AppState
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2)
            }
            .foregroundStyle(app.theme.textSecondary)
            .frame(width: 70)
            .padding(.vertical, 10)
            .background(app.theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(app.theme.border, lineWidth: 1))
        }
    }
}
