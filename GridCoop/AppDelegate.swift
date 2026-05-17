import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AdjustSdk

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var bootBridge: BootBridge!
    private let cropsFusion = CropsFusion()
    private let pushHarvester = PushHarvester()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        cropsFusion.cropsRelay = { [weak self] data in
            self?.broadcastCrops(data)
        }
        cropsFusion.furrowsRelay = { [weak self] data in
            self?.broadcastFurrows(data)
        }
        
        let impl = FarmBootImpl(
            messagingDelegate: self,
            notificationDelegate: self,
            adjustDelegate: self
        )
        bootBridge = BootBridge(implementation: impl)
        bootBridge.engage()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushHarvester.harvest(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Adjust.setPushToken(deviceToken)
    }
    
    @objc private func onActivation() {
        bootBridge.kickoffTracking()
    }
    
    private func broadcastCrops(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastFurrows(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: CoopLegacy.fcm)
            UserDefaults.standard.set(t, forKey: CoopLegacy.push)
            UserDefaults(suiteName: CoopConstants.suiteFarm)?.set(t, forKey: "shared_fcm")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushHarvester.harvest(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushHarvester.harvest(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushHarvester.harvest(userInfo)
        completionHandler(.newData)
    }
}

// MARK: - AdjustDelegate

extension AppDelegate: AdjustDelegate {
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        
        var data: [AnyHashable: Any] = [:]
        if let network      = attribution.network      { data["network"]       = network }
        if let campaign     = attribution.campaign     { data["campaign"]      = campaign }
        if let adgroup      = attribution.adgroup      { data["adgroup"]       = adgroup }
        if let creative     = attribution.creative     { data["creative"]      = creative }
        if let clickLabel   = attribution.clickLabel   { data["click_label"]   = clickLabel }
        if let trackerName  = attribution.trackerName  { data["tracker_name"]  = trackerName }
        if let trackerToken = attribution.trackerToken { data["tracker_token"] = trackerToken }
        if let costType     = attribution.costType     { data["cost_type"]     = costType }
        if let costAmount   = attribution.costAmount   { data["cost_amount"]   = costAmount }
        if let costCurrency = attribution.costCurrency { data["cost_currency"] = costCurrency }
        data["is_organic"] = attribution.network == nil || attribution.network == "Organic"
        
        cropsFusion.acceptCrops(data)
        
        NotificationCenter.default.post(name: .init("AdjustAttributionReceived"), object: nil)
    }
    
    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        let desc = sessionFailureResponseData?.message ?? "unknown"
        cropsFusion.acceptCrops(["error": true, "error_desc": desc])
    }
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        guard let deeplink else { return false }
        let data: [AnyHashable: Any] = [
            "deeplink_url":    deeplink.absoluteString,
            "deeplink_scheme": deeplink.scheme ?? "",
            "deeplink_host":   deeplink.host ?? "",
            "deeplink_path":   deeplink.path
        ]
        cropsFusion.acceptFurrows(data)
        return true
    }
}

// MARK: - Bridge Pattern

protocol BootImplementation {
    func setupFirebase()
    func setupMessaging()
    func setupAdjust()
    func kickoffTracking()
}

final class BootBridge {
    private let implementation: BootImplementation
    
    init(implementation: BootImplementation) {
        self.implementation = implementation
    }
    
    func engage() {
        print("\(CoopConstants.logHay) Bridge engaging bootstrap")
        implementation.setupFirebase()
        implementation.setupMessaging()
        implementation.setupAdjust()
    }
    
    func kickoffTracking() {
        implementation.kickoffTracking()
    }
}

final class FarmBootImpl: BootImplementation {
    
    private weak var messagingDelegate: MessagingDelegate?
    private weak var notificationDelegate: UNUserNotificationCenterDelegate?
    private weak var adjustDelegate: (NSObject & AdjustDelegate)?
    
    private static var trackingStarted = false
    
    init(
        messagingDelegate: MessagingDelegate,
        notificationDelegate: UNUserNotificationCenterDelegate,
        adjustDelegate: NSObject & AdjustDelegate
    ) {
        self.messagingDelegate = messagingDelegate
        self.notificationDelegate = notificationDelegate
        self.adjustDelegate = adjustDelegate
    }
    
    func setupFirebase() {
        FirebaseApp.configure()
    }
    
    func setupMessaging() {
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func setupAdjust() {
        // Adjust инициализируется после ATT в kickoffTracking
    }
    
    func kickoffTracking() {
        guard !FarmBootImpl.trackingStarted else { return }
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard !FarmBootImpl.trackingStarted else { return }
                    FarmBootImpl.trackingStarted = true
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    self?.initAdjust()
                    NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
                }
            }
        } else {
            FarmBootImpl.trackingStarted = true
            initAdjust()
            NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
        }
    }
    
    private func initAdjust() {
        guard let config = ADJConfig(
            appToken: CoopConstants.adjustAppToken,
            environment: ADJEnvironmentProduction
        ) else {
            return
        }
        config.delegate = adjustDelegate
        config.logLevel = ADJLogLevel.suppress
        Adjust.initSdk(config)
    }
}

// MARK: - Crops Fusion

final class CropsFusion: NSObject {
    
    var cropsRelay: (([AnyHashable: Any]) -> Void)?
    var furrowsRelay: (([AnyHashable: Any]) -> Void)?
    
    private var cropsBuffer: [AnyHashable: Any] = [:]
    private var furrowsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptCrops(_ data: [AnyHashable: Any]) {
        cropsBuffer = data
        scheduleFuse()
        if !furrowsBuffer.isEmpty { performFuse() }
    }
    
    func acceptFurrows(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: CoopLegacy.tilledDefaults) else { return }
        furrowsBuffer = data
        furrowsRelay?(data)
        fuseTimer?.invalidate()
        if !cropsBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = cropsBuffer
        for (k, v) in furrowsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        cropsRelay?(combined)
    }
}

// MARK: - Push Harvester

final class PushHarvester: NSObject {
    
    func harvest(_ payload: [AnyHashable: Any]) {
        guard let url = thresh(payload) else { return }
        UserDefaults.standard.set(url, forKey: CoopLegacy.pushURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func thresh(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
