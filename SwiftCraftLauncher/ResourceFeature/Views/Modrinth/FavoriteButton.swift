//
//  FavoriteButton.swift
//  ResourceFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import SwiftUI

/// A button that toggles the favorite state of a Modrinth project.
struct FavoriteButton: View {
    let projectId: String
    let query: String
    @State private var isFavorited: Bool = false
    @State private var isLoading: Bool = false

    private let store = FavoriteStore()

    var body: some View {
        Button {
            Task {
                await toggleFavorite()
            }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(1.3)
                } else {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundColor(isFavorited ? .red : .secondary)
                }
            }
            .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .applyReplaceTransition()
        .task {
            isFavorited = (try? store.isFavorite(id: projectId, type: query)) ?? false
        }
    }

    private func toggleFavorite() async {
        isLoading = true
        defer { isLoading = false }

        guard let detail = try? await ModrinthService.fetchProjectDetailsThrowing(id: projectId) else {
            return
        }

        if isFavorited {
            try? store.removeFavorite(id: projectId, type: query)
        } else {
            try? store.addFavorite(id: projectId, type: query, detail: detail)
        }
        isFavorited = (try? store.isFavorite(id: projectId, type: query)) ?? false
    }
}
