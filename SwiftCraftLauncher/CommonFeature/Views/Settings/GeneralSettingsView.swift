//
//  GeneralSettingsView.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import SwiftUI

/// A view for configuring general launcher settings.
public struct GeneralSettingsView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GeneralSettingsViewModel
    @EnvironmentObject private var gameRepository: GameRepository

    @MainActor
    public init() {
        _viewModel = StateObject(wrappedValue: GeneralSettingsViewModel())
    }

    public var body: some View {
        let generalSettingsManager = container.ui.generalSettingsManager
        Form {
            GeneralSettingsLanguageRow(languageManager: container.ui.languageManager)

            GeneralSettingsThemeRow()
                .environmentObject(container.ui.themeManager)

            GeneralSettingsInterfaceLayoutRow()
                .environmentObject(generalSettingsManager)

            GeneralSettingsWorkingDirectoryRow(
                viewModel: viewModel,
                gameRepository: gameRepository,
            )
            .environmentObject(generalSettingsManager)

            GeneralSettingsConcurrentDownloadsRow(
                viewModel: viewModel,
            )
            .environmentObject(generalSettingsManager)

            GeneralSettingsSystemProxyRow()

            GeneralSettingsGitHubProxyRow()
                .environmentObject(generalSettingsManager)

            GeneralSettingsCommonSheetHeightLimitRow()
                .environmentObject(generalSettingsManager)
        }
        .errorHandler(container.core.errorHandler)
        .onAppear {
            viewModel.configure(gameRepository: gameRepository)
        }
        .alert(
            "error.notification.validation.title".localized(),
            isPresented: .constant(viewModel.error != nil && viewModel.error?.level == .popup),
        ) {
            Button("common.close".localized()) {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}
