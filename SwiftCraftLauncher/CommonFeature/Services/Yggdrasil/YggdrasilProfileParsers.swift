//
//  YggdrasilProfileParsers.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Foundation

/// Defines the interface for parsing Yggdrasil profile list responses.
protocol YggdrasilProfileListParser {
    var id: YggdrasilProfileParserID { get }

    func parse(data: Data) async -> [YggdrasilProfileCandidate]?
}

enum YggdrasilProfileParsers {
    static func make(_ id: YggdrasilProfileParserID, baseURL: String) -> (any YggdrasilProfileListParser)? {
        switch id {
        case .littleskin:
            return CommonYggdrasilStyleProfileListParser(baseURL: baseURL)
        case .mua:
            return CommonBlessingSkinStyleProfileListParser(baseURL: baseURL)
        case .ely:
            return ElyflyProfileStyleProfileListParser(baseURL: baseURL)
        }
    }
}
