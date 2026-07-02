//
//  FavoriteStore.swift
//  ResourceFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Foundation
import SQLite3

/// Manages a local SQLite-backed collection of favorited Modrinth projects.
final class FavoriteStore {
    private let database: SQLiteDatabase
    private let tableName = AppConstants.DatabaseTables.favorites
    private var isInitialized = false

    private let createTableSQL: String
    private let insertSQL: String
    private let deleteSQL: String
    private let selectAllSQL: String
    private let selectByTypeSQL: String
    private let existsSQL: String

    init() {
        database = SQLiteDatabase(path: AppPaths.gameVersionDatabase.path)
        createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            id TEXT NOT NULL,
            type TEXT NOT NULL,
            project_detail BLOB NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            PRIMARY KEY (id, type)
        );
        """
        insertSQL = """
        INSERT OR REPLACE INTO \(tableName)
        (id, type, project_detail, created_at, updated_at)
        VALUES (?, ?, ?,
            COALESCE((SELECT created_at FROM \(tableName) WHERE id = ? AND type = ?), ?),
            ?)
        """
        deleteSQL = "DELETE FROM \(tableName) WHERE id = ? AND type = ?"
        selectAllSQL = "SELECT id, type, project_detail FROM \(tableName) ORDER BY created_at DESC"
        selectByTypeSQL = "SELECT id, project_detail FROM \(tableName) WHERE type = ? ORDER BY created_at DESC"
        existsSQL = "SELECT 1 FROM \(tableName) WHERE id = ? AND type = ? LIMIT 1"
    }

    /// Adds a favorite entry.
    @discardableResult
    func addFavorite(id: String, type: String, detail: ModrinthProjectDetail) -> Bool {
        do {
            try initializeIfNeeded()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(detail)
            let now = Date()

            try executeUpdate(insertSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: id)
                SQLiteDatabase.bind(statement, index: 2, value: type)
                SQLiteDatabase.bind(statement, index: 3, data: jsonData)
                SQLiteDatabase.bind(statement, index: 4, value: id)
                SQLiteDatabase.bind(statement, index: 5, value: type)
                SQLiteDatabase.bind(statement, index: 6, value: now)
                SQLiteDatabase.bind(statement, index: 7, value: now)
            }
            return true
        } catch {
            AppLog.common.error("Failed to add favorite id=\(id) type=\(type): \(error.localizedDescription)")
            return false
        }
    }

    /// Removes a favorite entry.
    @discardableResult
    func removeFavorite(id: String, type: String) -> Bool {
        do {
            try initializeIfNeeded()
            try executeUpdate(deleteSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: id)
                SQLiteDatabase.bind(statement, index: 2, value: type)
            }
            return true
        } catch {
            AppLog.common.error("Failed to remove favorite id=\(id) type=\(type): \(error.localizedDescription)")
            return false
        }
    }

    /// Checks whether a project is favorited.
    func isFavorite(id: String, type: String) -> Bool {
        do {
            try initializeIfNeeded()
            return try withPreparedStatement(existsSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: id)
                SQLiteDatabase.bind(statement, index: 2, value: type)
                return sqlite3_step(statement) == SQLITE_ROW
            }
        } catch {
            AppLog.common.error("Failed to check favorite id=\(id) type=\(type): \(error.localizedDescription)")
            return false
        }
    }

    /// Retrieves all favorite entries for a given resource type.
    func getFavorites(type: String) -> [ModrinthProjectDetail] {
        do {
            try initializeIfNeeded()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try withPreparedStatement(selectByTypeSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: type)
                var results: [ModrinthProjectDetail] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let jsonData = SQLiteDatabase.dataColumn(statement, index: 1) else { continue }
                    if let detail = try? decoder.decode(ModrinthProjectDetail.self, from: jsonData) {
                        results.append(detail)
                    }
                }
                return results
            }
        } catch {
            AppLog.common.error("Failed to get favorites type=\(type): \(error.localizedDescription)")
            return []
        }
    }

    /// Retrieves all favorite entries across all resource types.
    func getAllFavorites() -> [(id: String, type: String, detail: ModrinthProjectDetail)] {
        do {
            try initializeIfNeeded()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try withPreparedStatement(selectAllSQL) { statement in
                var results: [(id: String, type: String, detail: ModrinthProjectDetail)] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let id = SQLiteDatabase.stringColumn(statement, index: 0),
                          let type = SQLiteDatabase.stringColumn(statement, index: 1),
                          let jsonData = SQLiteDatabase.dataColumn(statement, index: 2) else { continue }
                    if let detail = try? decoder.decode(ModrinthProjectDetail.self, from: jsonData) {
                        results.append((id: id, type: type, detail: detail))
                    }
                }
                return results
            }
        } catch {
            AppLog.common.error("Failed to get all favorites: \(error.localizedDescription)")
            return []
        }
    }

    /// Removes all favorite entries.
    func clearAll() {
        do {
            try initializeIfNeeded()
            try database.execute("DELETE FROM \(tableName)")
        } catch {
            AppLog.common.error("Failed to clear favorites: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func initializeIfNeeded() throws {
        guard !isInitialized else { return }
        let dataDir = AppPaths.dataDirectory
        try FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        try database.open()
        try database.execute(createTableSQL)
        try? database.execute("CREATE INDEX IF NOT EXISTS idx_favorites_type ON \(tableName)(type);")
        isInitialized = true
    }

    private func withPreparedStatement<T>(
        _ sql: String,
        _ body: (OpaquePointer) throws -> T,
    ) throws -> T {
        let statement = try database.prepare(sql)
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func executeUpdate(
        _ sql: String,
        bind: (OpaquePointer) throws -> Void,
    ) throws {
        try database.transaction {
            try withPreparedStatement(sql) { statement in
                try bind(statement)
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    let db = database.database
                    let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown"
                    throw GlobalError.validation(
                        i18nKey: "error.validation.sql_execution_failed",
                        level: .notification,
                        message: "SQLite error: \(msg)",
                    )
                }
            }
        }
    }
}
