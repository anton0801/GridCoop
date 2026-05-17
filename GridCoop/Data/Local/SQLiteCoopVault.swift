import Foundation
import SQLite3

protocol CoopVault {
    func stashCrops(_ data: [String: String])
    func stashFurrows(_ data: [String: String])
    func stashBarn(url: String, mode: String)
    func stashConsent(sown: Bool, fallow: Bool, at: Date?)
    func markTilled()
    func defrost() -> CoopBundle
}

final class SQLiteCoopVault: CoopVault {
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.gridcoop.sqlite", qos: .userInitiated)
    private let homeVault: UserDefaults
    private let suiteVault: UserDefaults
    
    init() {
        self.homeVault = UserDefaults.standard
        self.suiteVault = UserDefaults(suiteName: CoopConstants.suiteFarm) ?? .standard
        openDatabase()
        ensureSchema()
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        let docs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        if !FileManager.default.fileExists(atPath: docs.path) {
            try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        }
        
        let dbPath = docs.appendingPathComponent(CoopConstants.sqliteFile).path
        
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("\(CoopConstants.logHay) sqlite3_open failed: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    private func ensureSchema() {
        let sql = "CREATE TABLE IF NOT EXISTS \(CoopSchema.table) (\(CoopSchema.columnKey) TEXT PRIMARY KEY, \(CoopSchema.columnValue) TEXT);"
        execute(sql)
    }
    
    // MARK: - Stash
    
    func stashCrops(_ data: [String: String]) {
        guard let encoded = encodeJSON(data) else { return }
        upsert(key: CoopSchema.kCrops, value: encoded)
    }
    
    func stashFurrows(_ data: [String: String]) {
        guard let encoded = encodeJSON(data) else { return }
        let veiled = veil(encoded)
        upsert(key: CoopSchema.kFurrows, value: veiled)
    }
    
    func stashBarn(url: String, mode: String) {
        upsert(key: CoopSchema.kBarnURL, value: url)
        upsert(key: CoopSchema.kBarnMode, value: mode)
        homeVault.set(url, forKey: CoopLegacy.barnURLDefaults)
        suiteVault.set(url, forKey: CoopLegacy.barnURLDefaults)
    }
    
    func stashConsent(sown: Bool, fallow: Bool, at: Date?) {
        upsert(key: CoopSchema.kConsentSown, value: sown ? "1" : "0")
        upsert(key: CoopSchema.kConsentFallow, value: fallow ? "1" : "0")
        if let when = at {
            upsert(key: CoopSchema.kConsentTilledAt, value: String(when.timeIntervalSince1970 * 1000))
        }
    }
    
    func markTilled() {
        upsert(key: CoopSchema.kTilled, value: "1")
        homeVault.set(true, forKey: CoopLegacy.tilledDefaults)
        suiteVault.set(true, forKey: CoopLegacy.tilledDefaults)
    }
    
    // MARK: - Defrost
    
    func defrost() -> CoopBundle {
        let cropsRaw = readValue(key: CoopSchema.kCrops) ?? ""
        let crops = decodeJSON(cropsRaw) ?? [:]
        
        let furrowsVeiled = readValue(key: CoopSchema.kFurrows) ?? ""
        let furrowsRaw = unveil(furrowsVeiled)
        let furrows = decodeJSON(furrowsRaw) ?? [:]
        
        let barnURL = readValue(key: CoopSchema.kBarnURL) ?? homeVault.string(forKey: CoopLegacy.barnURLDefaults)
        let barnMode = readValue(key: CoopSchema.kBarnMode)
        let tilled = readValue(key: CoopSchema.kTilled) == "1"
        
        let sown = readValue(key: CoopSchema.kConsentSown) == "1"
        let fallow = readValue(key: CoopSchema.kConsentFallow) == "1"
        let atMs = Double(readValue(key: CoopSchema.kConsentTilledAt) ?? "") ?? 0
        let at = atMs > 0 ? Date(timeIntervalSince1970: atMs / 1000) : nil
        
        return CoopBundle(
            crops: crops,
            furrows: furrows,
            barnURL: barnURL,
            barnMode: barnMode,
            untilled: !tilled,
            consentSown: sown,
            consentFallow: fallow,
            consentTilledAt: at
        )
    }
    
    // MARK: - SQLite primitives
    
    private func execute(_ sql: String) {
        dbQueue.sync {
            var error: UnsafeMutablePointer<Int8>?
            if sqlite3_exec(db, sql, nil, nil, &error) != SQLITE_OK {
                if let e = error {
                    print("\(CoopConstants.logHay) SQL exec failed: \(String(cString: e))")
                    sqlite3_free(error)
                }
            }
        }
    }
    
    private func upsert(key: String, value: String) {
        dbQueue.sync {
            let sql = "INSERT OR REPLACE INTO \(CoopSchema.table) (\(CoopSchema.columnKey), \(CoopSchema.columnValue)) VALUES (?, ?);"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, value, -1, SQLITE_TRANSIENT)
                if sqlite3_step(stmt) != SQLITE_DONE {
                    print("\(CoopConstants.logHay) upsert failed for \(key)")
                }
            }
            sqlite3_finalize(stmt)
        }
    }
    
    private func readValue(key: String) -> String? {
        return dbQueue.sync { () -> String? in
            let sql = "SELECT \(CoopSchema.columnValue) FROM \(CoopSchema.table) WHERE \(CoopSchema.columnKey) = ?;"
            var stmt: OpaquePointer?
            var result: String?
            
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(stmt, 0) {
                        result = String(cString: cString)
                    }
                }
            }
            sqlite3_finalize(stmt)
            return result
        }
    }
    
    // MARK: - JSON helpers
    
    private func encodeJSON(_ dict: [String: String]) -> String? {
        let any = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: any),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
    
    private func decodeJSON(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return any.mapValues { "\($0)" }
    }
    
    // MARK: - Veiling
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "*")
            .replacingOccurrences(of: "+", with: "?")
    }
    
    private func unveil(_ input: String) -> String {
        let b64 = input
            .replacingOccurrences(of: "*", with: "=")
            .replacingOccurrences(of: "?", with: "+")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }
}
