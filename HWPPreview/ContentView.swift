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
        VStack(spacing: OnboardingLayout.sectionSpacing) {
            hero
            quickSteps
            actions
        }
        .padding(OnboardingLayout.windowPadding)
        .frame(width: OnboardingLayout.contentWidth)
        .background(Color(nsColor: .windowBackgroundColor))
        .fixedSize(horizontal: true, vertical: true)
        .sheet(isPresented: $isShowingGuide) {
            ExtensionGuideSheet(didFailToOpenSettings: didFailToOpenSettings)
        }
    }

    private var hero: some View {
        VStack(spacing: OnboardingLayout.heroSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: OnboardingLayout.iconCornerRadius, style: .continuous)
                    .fill(.tint.opacity(OnboardingLayout.iconBackgroundOpacity))
                    .frame(width: OnboardingLayout.iconSize, height: OnboardingLayout.iconSize)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: OnboardingLayout.iconSymbolSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: OnboardingLayout.titleSpacing) {
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
                    .frame(maxWidth: OnboardingLayout.descriptionWidth)
            }
        }
        .padding(.vertical, OnboardingLayout.heroVerticalPadding)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: OnboardingLayout.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OnboardingLayout.cardCornerRadius, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private var quickSteps: some View {
        HStack(spacing: OnboardingLayout.stepSpacing) {
            StepCard(symbol: "doc.text.fill", title: "파일 선택", detail: ".hwp 또는 .hwpx")
            StepCard(symbol: "keyboard", title: "Space", detail: "Quick Look 열기")
            StepCard(symbol: "checkmark.circle.fill", title: "미리보기", detail: "문서 바로 확인")
        }
    }

    private var actions: some View {
        VStack(spacing: OnboardingLayout.actionSpacing) {
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
        .padding(.top, OnboardingLayout.actionTopPadding)
    }
}

private struct StepCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: OnboardingLayout.stepContentSpacing) {
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
        .padding(.vertical, OnboardingLayout.stepVerticalPadding)
        .background(.quaternary.opacity(OnboardingLayout.stepBackgroundOpacity), in: RoundedRectangle(cornerRadius: OnboardingLayout.stepCornerRadius, style: .continuous))
    }
}

private struct ExtensionGuideSheet: View {
    let didFailToOpenSettings: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingLayout.sheetSectionSpacing) {
            VStack(alignment: .leading, spacing: OnboardingLayout.sheetTitleSpacing) {
                Text(didFailToOpenSettings ? "설정을 자동으로 열 수 없어요" : "확장이 꺼져 있다면")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Quick Look 확장은 macOS 시스템에서 관리함으로 HWPPreview에서 자동으로 켤 수 없어요. 아래 안내를 따라 확장을 켜주세요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: OnboardingLayout.guideRowSpacing) {
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
        .padding(OnboardingLayout.sheetPadding)
        .frame(width: OnboardingLayout.sheetWidth)
    }
}

private struct GuideRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: OnboardingLayout.guideRowIconSpacing) {
            Text("\(number)")
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: OnboardingLayout.guideBadgeSize, height: OnboardingLayout.guideBadgeSize)
                .background(.tint, in: Circle())

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private enum OnboardingLayout {
    static let contentWidth: CGFloat = 500
    static let descriptionWidth: CGFloat = 380
    static let sheetWidth: CGFloat = 460

    static let windowPadding: CGFloat = 24
    static let sheetPadding: CGFloat = 26
    static let heroVerticalPadding: CGFloat = 24
    static let stepVerticalPadding: CGFloat = 15
    static let actionTopPadding: CGFloat = 2

    static let sectionSpacing: CGFloat = 18
    static let heroSpacing: CGFloat = 14
    static let titleSpacing: CGFloat = 8
    static let stepSpacing: CGFloat = 10
    static let stepContentSpacing: CGFloat = 8
    static let actionSpacing: CGFloat = 12
    static let sheetSectionSpacing: CGFloat = 20
    static let sheetTitleSpacing: CGFloat = 8
    static let guideRowSpacing: CGFloat = 14
    static let guideRowIconSpacing: CGFloat = 12

    static let cardCornerRadius: CGFloat = 22
    static let stepCornerRadius: CGFloat = 16
    static let iconCornerRadius: CGFloat = 22

    static let iconSize: CGFloat = 72
    static let iconSymbolSize: CGFloat = 32
    static let guideBadgeSize: CGFloat = 24

    static let iconBackgroundOpacity = 0.12
    static let stepBackgroundOpacity = 0.65
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
