//
//  AppServices.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Foundation
import MinecraftFriendsKit

/// A global namespace that owns and exposes all shared service instances.
enum AppServices {
    @inline(__always)
    private static func mainActorSingleton<T>(
        _ factory: @MainActor () -> T,
    ) -> T {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(factory)
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(factory)
        }
    }

    // Error handling

    static let errorHandler = GlobalErrorHandler()

    // Cache

    static let appCacheManager = AppCacheManager()
    static let cacheCalculator = CacheCalculator()
    static let cacheInfoManager = CacheInfoManager()

    // Mods

    static let modScanner = ModScanner()
    static let modCacheManager = ModCacheManager()
    static let modDirectoryWatcherRegistry = ModDirectoryWatcherRegistry()
    static let modInstallationCache = ModScanner.ModInstallationCache()
    static let directoryHashCache = ModScanner.DirectoryHashCache()

    // Window & UI

    static let windowManager = mainActorSingleton { WindowManager() }
    static let windowDataStore = mainActorSingleton { WindowDataStore() }
    static let iconRefreshNotifier = IconRefreshNotifier()

    static let gameDialogsPresenter = mainActorSingleton { GameDialogsPresenter() }
    static let authlibInjectorMissingPresenter = mainActorSingleton {
        AuthlibInjectorMissingPresenter()
    }

    static let openURLModPackImportPresenter = mainActorSingleton {
        OpenURLModPackImportPresenter()
    }

    // Game

    static let gameProcessManager = GameProcessManager()
    static let gameStatusManager = GameStatusManager()
    static let gameLogCollector = mainActorSingleton { GameLogCollector() }
    static let gameActionManager = mainActorSingleton { GameActionManager() }

    // Settings

    static let announcementStateManager = mainActorSingleton {
        AnnouncementStateManager()
    }

    static let generalSettingsManager = GeneralSettingsManager()
    static let gameSettingsManager = GameSettingsManager()
    static let playerSettingsManager = PlayerSettingsManager()
    static let playerDataManager = PlayerDataManager()
    static let selectedGameManager = SelectedGameManager()
    static let themeManager = mainActorSingleton { ThemeManager() }
    static let languageManager = LanguageManager()

    // Minecraft Friends

    static let minecraftFriendsPresencePollingCoordinator = mainActorSingleton {
        MinecraftFriendsPresencePollingCoordinator()
    }

    static let minecraftFriendsService = MinecraftFriendsService()

    // Authentication & Network

    static let gitHubService = mainActorSingleton { GitHubService() }
    static let minecraftAuthService = MinecraftAuthService()
    static let yggdrasilAuthService = YggdrasilAuthService()
    static let ipLocationService = mainActorSingleton { IPLocationService() }

    // Java

    static let javaManager = JavaManager()
    static let javaRuntimeService = JavaRuntimeService()
    static let javaRuntimeDownloader = JavaRuntimeDownloader()
    static let javaDownloadManager = mainActorSingleton { JavaDownloadManager() }

    // AI

    static let aiSettingsManager = AISettingsManager()
    static let aiChatManager = mainActorSingleton { AIChatManager() }

    // Utilities

    static let sparkleUpdateService = SparkleUpdateService()
    static let serverAddressService = mainActorSingleton { ServerAddressService() }
    static let litematicaService = mainActorSingleton { LitematicaService() }
    static let premiumAccountFlagManager = mainActorSingleton { PremiumAccountFlagManager() }
}
