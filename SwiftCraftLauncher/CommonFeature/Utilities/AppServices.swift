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
    private static func mainActorSingleton<T>(_ factory: @MainActor () -> T) -> T {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(factory)
        }
        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(factory)
        }
    }

    nonisolated(unsafe) static let errorHandler = GlobalErrorHandler()

    nonisolated(unsafe) static let appCacheManager = AppCacheManager()
    nonisolated(unsafe) static let cacheCalculator = CacheCalculator()
    nonisolated(unsafe) static let cacheInfoManager = CacheInfoManager()

    nonisolated(unsafe) static let modScanner = ModScanner()
    nonisolated(unsafe) static let modCacheManager = ModCacheManager()
    nonisolated(unsafe) static let modDirectoryWatcherRegistry = ModDirectoryWatcherRegistry()
    nonisolated(unsafe) static let modInstallationCache = ModScanner.ModInstallationCache()
    nonisolated(unsafe) static let directoryHashCache = ModScanner.DirectoryHashCache()

    nonisolated(unsafe) static let windowManager = mainActorSingleton { WindowManager() }
    nonisolated(unsafe) static let windowDataStore = mainActorSingleton { WindowDataStore() }
    nonisolated(unsafe) static let iconRefreshNotifier = IconRefreshNotifier()
    nonisolated(unsafe) static let gameDialogsPresenter = mainActorSingleton { GameDialogsPresenter() }
    nonisolated(unsafe) static let authlibInjectorMissingPresenter = mainActorSingleton { AuthlibInjectorMissingPresenter() }
    nonisolated(unsafe) static let openURLModPackImportPresenter = mainActorSingleton { OpenURLModPackImportPresenter() }

    nonisolated(unsafe) static let gameProcessManager = GameProcessManager()
    nonisolated(unsafe) static let gameStatusManager = GameStatusManager()
    nonisolated(unsafe) static let gameLogCollector = mainActorSingleton { GameLogCollector() }
    nonisolated(unsafe) static let gameActionManager = mainActorSingleton { GameActionManager() }

    nonisolated(unsafe) static let announcementStateManager = mainActorSingleton { AnnouncementStateManager() }
    nonisolated(unsafe) static let generalSettingsManager = GeneralSettingsManager()
    nonisolated(unsafe) static let gameSettingsManager = GameSettingsManager()
    nonisolated(unsafe) static let playerSettingsManager = PlayerSettingsManager()
    nonisolated(unsafe) static let playerDataManager = PlayerDataManager()
    nonisolated(unsafe) static let selectedGameManager = SelectedGameManager()
    nonisolated(unsafe) static let themeManager = mainActorSingleton { ThemeManager() }
    nonisolated(unsafe) static let languageManager = LanguageManager()

    nonisolated(unsafe) static let minecraftFriendsPresencePollingCoordinator = mainActorSingleton {
        MinecraftFriendsPresencePollingCoordinator()
    }

    nonisolated(unsafe) static let gitHubService = mainActorSingleton { GitHubService() }
    nonisolated(unsafe) static let minecraftAuthService = MinecraftAuthService()
    nonisolated(unsafe) static let yggdrasilAuthService = YggdrasilAuthService()
    nonisolated(unsafe) static let ipLocationService = mainActorSingleton { IPLocationService() }

    nonisolated(unsafe) static let javaManager = JavaManager()
    nonisolated(unsafe) static let javaRuntimeService = JavaRuntimeService()
    nonisolated(unsafe) static let javaRuntimeDownloader = JavaRuntimeDownloader()
    nonisolated(unsafe) static let javaDownloadManager = mainActorSingleton { JavaDownloadManager() }

    nonisolated(unsafe) static let aiSettingsManager = AISettingsManager()
    nonisolated(unsafe) static let aiChatManager = mainActorSingleton { AIChatManager() }
    nonisolated(unsafe) static let sparkleUpdateService = SparkleUpdateService()

    nonisolated(unsafe) static let serverAddressService = mainActorSingleton { ServerAddressService() }
    nonisolated(unsafe) static let litematicaService = mainActorSingleton { LitematicaService() }
    nonisolated(unsafe) static let premiumAccountFlagManager = mainActorSingleton { PremiumAccountFlagManager() }

    nonisolated(unsafe) static let minecraftFriendsService = MinecraftFriendsService()
}
