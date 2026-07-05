//
//  YggdrasilAuthService+TokenChain.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Foundation

/// Performs Yggdrasil OAuth2 token exchange and profile retrieval.
extension YggdrasilAuthService {
    func exchangeCodeForToken(code: String, server: YggdrasilServerConfig) async throws -> TokenResponse {
        guard let tokenURL = server.tokenURL else {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_token_url_invalid",
                level: .notification,
                message: "Yggdrasil token URL is nil for server \(server.baseURL.absoluteString)",
            )
        }

        var parameters: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": server.redirectURI,
        ]

        if let clientId = server.clientId {
            parameters["client_id"] = clientId
        }
        if let clientSecret = server.clientSecret {
            parameters["client_secret"] = clientSecret
        }

        let data = try await APIClient.post(
            url: tokenURL,
            body: APIClient.formURLEncodedBody(from: parameters),
            headers: APIClient.DefaultHeaders.contentTypeFormURLEncoded,
        )

        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_token_response_parse_failed",
                level: .notification,
                message: "Failed to parse Yggdrasil token response from \(tokenURL): \(error.localizedDescription)",
            )
        }
    }

    func refreshToken(refreshToken: String, server: YggdrasilServerConfig) async throws -> TokenResponse {
        guard let refreshTokenURL = server.tokenURL else {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_refresh_token_url_invalid",
                level: .notification,
                message: "Yggdrasil refresh token URL is nil for server \(server.baseURL.absoluteString)",
            )
        }

        AppLog.common.debug("Refreshing token for server \(server.name)")

        var parameters: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]

        if let clientId = server.clientId {
            parameters["client_id"] = clientId
        }
        if let clientSecret = server.clientSecret {
            parameters["client_secret"] = clientSecret
        }

        do {
            let data = try await APIClient.post(
                url: refreshTokenURL,
                body: APIClient.formURLEncodedBody(from: parameters),
                headers: APIClient.DefaultHeaders.contentTypeFormURLEncoded,
            )
            AppLog.common.info("Token refreshed successfully for server \(server.name)")
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_token_response_parse_failed",
                level: .silent,
                message: "Failed to parse Yggdrasil refresh token response from \(refreshTokenURL): \(error.localizedDescription)",
            )
        }
    }

    func fetchProfileList(
        accessToken: String,
        server: YggdrasilServerConfig,
    ) async throws -> [YggdrasilProfileCandidate] {
        guard let profileURL = server.profileURL else {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_profile_url_invalid",
                level: .notification,
                message: "Yggdrasil profile URL is nil for server \(server.baseURL.absoluteString)",
            )
        }

        let headers = [APIClient.Header.authorization: APIClient.bearer(accessToken)]
        let data = try await APIClient.get(url: profileURL, headers: headers)

        guard let parser = YggdrasilProfileParsers.make(server.parserId, baseURL: server.baseURL.absoluteString) else {
            throw GlobalError.validation(
                i18nKey: "error.validation.yggdrasil_profile_parse_failed",
                level: .notification,
                message: "No profile parser available for parserId=\(server.parserId), server=\(server.baseURL.absoluteString)",
            )
        }

        if let candidates = await parser.parse(data: data) {
            return candidates
        }

        throw GlobalError.validation(
            i18nKey: "error.validation.yggdrasil_profile_parse_failed",
            level: .notification,
            message: "Profile parser returned nil for parserId=\(server.parserId), server=\(server.baseURL.absoluteString), data size=\(data.count)",
        )
    }

    func getMinecraftToken(profile: YggdrasilProfile, server: YggdrasilServerConfig) async throws -> String {
        var updatedProfile = profile
        do {
            let tokenResponse = try await refreshToken(
                refreshToken: profile.refreshToken,
                server: server,
            )
            updatedProfile = YggdrasilProfile(
                id: profile.id,
                name: profile.name,
                skins: profile.skins,
                capes: profile.capes,
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? profile.refreshToken,
                serverBaseURL: profile.serverBaseURL,
            )
        } catch {
            DIContainer.shared.core.errorHandler.handle(error)
        }

        OfflineUserServerMap.setServer(updatedProfile)

        guard let parser = YggdrasilMinecraftTokenParsers.make(for: server.parserId) else {
            AppLog.common.error("TODO: Minecraft token fetch not yet implemented for this server (\(server.name)), falling back to OAuth2 token")
            return updatedProfile.accessToken
        }

        return try await parser.fetchMinecraftToken(
            profileId: updatedProfile.id,
            minecraftTokenURL: server.minecraftTokenURL,
            oauthToken: updatedProfile.accessToken,
        )
    }
}
