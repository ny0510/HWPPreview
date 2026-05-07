//
//  ContentView.swift
//  HWPPreview
//
//  Created by ny64 on 5/6/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @State private var isShowingGuide = false
    @State private var didFailToOpenSettings = false

    var body: some View {
        VStack(spacing: 22) {
            hero
            quickSteps
            actions
        }
        .padding(28)
        .frame(width: 520)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background)
        }
        .fixedSize()
        .sheet(isPresented: $isShowingGuide) {
            ExtensionGuideSheet(didFailToOpenSettings: didFailToOpenSettings)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.tint.opacity(0.12))
                    .frame(width: 78, height: 78)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 8) {
                Text("HWPPreview")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Finder에서 한글 문서를 바로 훑어보기")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(".hwp와 .hwpx 파일을 선택하고 Space를 누르면 별도 앱 실행 없이 내용을 미리 볼 수 있습니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 410)
            }
        }
    }

    private var quickSteps: some View {
        HStack(spacing: 12) {
            StepCard(symbol: "doc.text.fill", title: "파일 선택", detail: ".hwp 또는 .hwpx")
            StepCard(symbol: "keyboard", title: "Space", detail: "Quick Look 열기")
            StepCard(symbol: "checkmark.circle.fill", title: "미리보기", detail: "문서 바로 확인")
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                didFailToOpenSettings = !ExtensionSettingsLauncher.openSystemSettings()
                isShowingGuide = true
            } label: {
                Label("훑어보기 확장 설정 열기", systemImage: "switch.2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("미리보기가 안 보인다면?") {
                didFailToOpenSettings = false
                isShowingGuide = true
            }
            .buttonStyle(.plain)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
}

private struct StepCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.tint)

            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.quaternary.opacity(0.65), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ExtensionGuideSheet: View {
    let didFailToOpenSettings: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(didFailToOpenSettings ? "설정을 자동으로 열 수 없어요" : "확장이 꺼져 있다면")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Quick Look 확장은 macOS 시스템에서 관리함으로 HWPPreview에서 자동으로 켤 수 없어요. 아래 안내를 따라 확장을 켜주세요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                GuideRow(number: 1, text: "시스템 설정을 엽니다.")
                GuideRow(number: 2, text: "일반 > 로그인 항목 및 확장 프로그램으로 이동합니다.")
                GuideRow(number: 3, text: "확장 프로그램 목록에서 HWPPreview의 훑어보기 확장을 켭니다.")
            }

            Text("목록에 보이지 않으면 HWPPreview.app을 Applications 폴더로 옮긴 뒤 앱을 다시 실행하세요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("확인") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(26)
        .frame(width: 460)
    }
}

private struct GuideRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(number)")
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.tint, in: Circle())

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private enum ExtensionSettingsLauncher {
    private static let settingsURLs = [
        URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences"),
        URL(string: "x-apple.systempreferences:com.apple.preferences.extensions"),
        URL(string: "x-apple.systempreferences:")
    ].compactMap { $0 }

    @MainActor
    static func openSystemSettings() -> Bool {
        for url in settingsURLs where NSWorkspace.shared.open(url) {
            return true
        }

        return false
    }
}
