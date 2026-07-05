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
    private let db: SQLiteDatabase
    private let tableName = AppConstants.DatabaseTables.favorites
    private var isInitialized = false

    private let createTableSQL: String
    private let insertSQL: String
    private let deleteSQL: String
    private let selectAllSQL: String
    private let selectByTypeSQL: String
    private let existsSQL: String

    init() {
        db = SQLiteDatabase.database(at: AppPaths.gameVersionDatabase.path)
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
    func addFavorite(id: String, type: String, detail: ModrinthProjectDetail) throws {
        try initializeIfNeeded()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let jsonData = try encoder.encode(detail)
        let now = Date()

        try db.transaction {
            try withPreparedStatement(insertSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: id)
                SQLiteDatabase.bind(statement, index: 2, value: type)
                SQLiteDatabase.bind(statement, index: 3, data: jsonData)
                SQLiteDatabase.bind(statement, index: 4, value: id)
                SQLiteDatabase.bind(statement, index: 5, value: type)
                SQLiteDatabase.bind(statement, index: 6, value: now)
                SQLiteDatabase.bind(statement, index: 7, value: now)
                try stepStatement(statement)
            }
        }
    }

    /// Removes a favorite entry.
    func removeFavorite(id: String, type: String) throws {
        try initializeIfNeeded()
        try db.transaction {
            try withPreparedStatement(deleteSQL) { statement in
                SQLiteDatabase.bind(statement, index: 1, value: id)
                SQLiteDatabase.bind(statement, index: 2, value: type)
                try stepStatement(statement)
            }
        }
    }

    /// Checks whether a project is favorited.
    func isFavorite(id: String, type: String) throws -> Bool {
        try initializeIfNeeded()
        return try withPreparedStatement(existsSQL) { statement in
            SQLiteDatabase.bind(statement, index: 1, value: id)
            SQLiteDatabase.bind(statement, index: 2, value: type)
            return sqlite3_step(statement) == SQLITE_ROW
        }
    }

    /// Retrieves all favorite entries for a given resource type.
    func getFavorites(type: String) throws -> [ModrinthProjectDetail] {
        try initializeIfNeeded()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

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
    }

    /// Retrieves all favorite entries across all resource types.
    func getAllFavorites() throws -> [(id: String, type: String, detail: ModrinthProjectDetail)] {
        try initializeIfNeeded()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

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
    }

    /// Removes all favorite entries.
    func clearAll() throws {
        try initializeIfNeeded()
        try db.transaction {
            try db.execute("DELETE FROM \(tableName)")
        }
    }

    private func initializeIfNeeded() throws {
        guard !isInitialized else { return }
        try ensureDirectoriesIfNeeded()
        try db.open()
        try createTableIfNeeded()
        try createIndexesIfNeeded()
        isInitialized = true
    }

    private func ensureDirectoriesIfNeeded() throws {
        try FileManager.default.createDirectory(
            at: AppPaths.dataDirectory,
            withIntermediateDirectories: true,
        )
    }

    private func createTableIfNeeded() throws {
        try db.execute(createTableSQL)
    }

    private func createIndexesIfNeeded() throws {
        try? db.execute(
            "CREATE INDEX IF NOT EXISTS idx_favorites_type ON \(tableName)(type);",
        )
    }

    private func withPreparedStatement<T>(
        _ sql: String,
        _ body: (OpaquePointer) throws -> T,
    ) throws -> T {
        let statement = try db.prepare(sql)
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func stepStatement(_ statement: OpaquePointer) throws {
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db.database))
            throw GlobalError.validation(
                i18nKey: "error.validation.sql_execution_failed",
                level: .notification,
                message: "SQLite step failed, expected SQLITE_DONE. Error: \(errorMessage)",
            )
        }
    }
}
