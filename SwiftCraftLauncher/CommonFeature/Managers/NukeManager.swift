//
//  NukeManager.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Nuke
import SwiftUI

struct NukeManager {
    let pipeline: ImagePipeline

    init() {
        var config = ImagePipeline.Configuration()
        let cache = try? DataCache(
            path: AppPaths.imageCachae
        )
        cache?.sizeLimit = 200 << 20
        config.dataCache = cache
        config.isRateLimiterEnabled = false
        config.dataLoader = {
            let session = URLSessionConfiguration.default
            session.requestCachePolicy = .reloadIgnoringLocalCacheData
            return DataLoader(configuration: session)
        }()
        self.pipeline = ImagePipeline(configuration: config)
    }
}

// Represents the loading state of an image request
enum NukeImagePhase {
    case empty
    case loading
    case success(Image)
    case failure(Error)
}
