//
//  NukeImageView.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Nuke
import SwiftUI

struct NukeImageView<Content: View>: View {
    @EnvironmentObject private var container: DIContainer

    let url: URL?
    let content: (NukeImagePhase) -> Content

    @State private var phase: NukeImagePhase = .empty
    @State private var task: ImageTask?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (NukeImagePhase) -> Content,
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            // Automatically reload when URL changes and cancel previous task
                .task(id: url) {
                    load()
                }
    }

    private func load() {
        task?.cancel()

        guard let url else {
            phase = .empty
            return
        }

        phase = .loading

        // Start image request using shared pipeline
        task = container.system.nukeManager.pipeline.loadImage(with: url) { result in
            Task { @MainActor in
                switch result {
                case let .success(response):
                    phase = .success(Image(nsImage: response.image))

                case let .failure(error):
                    phase = .failure(error)
                }
            }
        }
    }
}
