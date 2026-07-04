//
//  GameMoreMenu.swift
//  MainFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit
import SwiftUI

/// Displays a context menu with additional actions for the selected game.
struct GameMoreMenu: View {
    @EnvironmentObject private var container: DIContainer
    let game: GameVersionInfo

    @Environment(\.openSettings)
    private var openSettings
    @EnvironmentObject private var detailState: ResourceDetailState

    init(
        game: GameVersionInfo,
    ) {
        self.game = game
    }

    var body: some View {
        Menu {
            if game.modLoader != GameLoader.vanilla.displayName {
                Button {
                    container.ui.gameDialogsPresenter.presentModPackExport(for: game)
                } label: {
                    Label("modpack.export.button".localized(), systemImage: "square.and.arrow.up")
                }
            }

            Button {
                container.core.selectedGameManager.setSelectedGameAndOpenAdvancedSettings(game.id)
                openSettings()
            } label: {
                Label(
                    "settings.game.advanced".localized(),
                    systemImage: "gearshape",
                )
            }

            Divider()

            Button(role: .destructive) {
                container.ui.gameDialogsPresenter.requestGameDeletion(of: game)
            } label: {
                Label("sidebar.context_menu.delete_game".localized(), systemImage: "trash")
            }
        } label: {
            Label("more".localized(), systemImage: "gearshape")
        }
        .help("more".localized())
    }
}
