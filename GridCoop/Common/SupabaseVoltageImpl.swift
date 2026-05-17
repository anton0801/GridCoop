import Foundation
import AdjustSdk
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

struct CoopConstants {
    static let appCode = "6763560234"
    
    static let adjustAppToken = "imk13achykn4"
    
    static let suiteFarm    = "group.gridcoop.farm"
    static let cookieNest   = "gridcoop_nest"
    static let backendField = "https://gridcoop.com/config.php"
    static let logHay       = "🌾 [GridCoop]"
    static let sqliteFile   = "gc_farm.sqlite"
}

final class SupabaseVoltageImpl {
    
    func probe() async throws -> Bool {
        return true
    }
}

final class HTTPBarnLocatorImpl {
    
    private let session: URLSession
    private let retryDelays: [Double] = [70.0, 140.0, 280.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func locate(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: CoopConstants.backendField) else {
            throw CoopError.dataSpoiled(at: "endpoint URL")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        // Adjust device ID вместо AppsFlyer UID
        body["adjust_id"] = await Adjust.adid() ?? ""
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(CoopConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: CoopLegacy.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastError: Error?
        var attempt = 0
        
        for (idx, delay) in retryDelays.enumerated() {
            attempt += 1
            do {
                return try await singleShot(request)
            } catch let err as CoopError {
                if case .barnRefused = err { throw err }
                if case .rateChoked(let after) = err {
                    try await Task.sleep(nanoseconds: UInt64(after * 1_000_000_000))
                    continue
                }
                lastError = err
                if idx < retryDelays.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                if idx < retryDelays.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        if let lastError = lastError { throw lastError }
        throw CoopError.wireWithered(attempt: attempt)
    }
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw CoopError.wireWithered(attempt: 0)
        }
        
        if http.statusCode == 404 {
            throw CoopError.barnRefused(httpCode: 404)
        }
        
        if http.statusCode == 429 {
            let retryAfter = TimeInterval(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw CoopError.rateChoked(retryAfter: retryAfter)
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw CoopError.wireWithered(attempt: 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoopError.dataSpoiled(at: "JSON parse")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw CoopError.dataSpoiled(at: "missing 'ok'")
        }
        
        if !ok {
            throw CoopError.barnRefused(httpCode: 200)
        }
        
        guard let url = json["url"] as? String else {
            throw CoopError.dataSpoiled(at: "missing 'url'")
        }
        
        return url
    }
}

final class NotificationConsentImpl {
    
    func request() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                }
                DispatchQueue.main.async {
                    continuation.yield(granted)
                    continuation.finish()
                }
            }
        }
    }
    
    func arm() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
