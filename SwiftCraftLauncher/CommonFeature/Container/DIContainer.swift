//
//  DIContainer.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Combine
import Foundation
import MinecraftFriendsKit
import SwiftUI

/// Centralized dependency container that owns all shared service instances.
/// AppServices delegates to this container internally.
final class DIContainer: ObservableObject {
    static let shared = DIContainer()

    // UI

    var ui = UIContainer()

    // Core

    var core = CoreContainer()

    // System

    var system = SystemContainer()

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Forward objectWillChange from nested ObservableObject instances so that
        // @EnvironmentObject consumers pick up state changes (e.g. game running/launching).
        core.gameStatusManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        ui.themeManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        ui.generalSettingsManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        system.minecraftAuthService
            .objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        system.yggdrasilAuthService
            .objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
