import Foundation

struct VoltageProbe {
    let probe: () async throws -> Bool
    
    static let live = VoltageProbe(
        probe: SupabaseVoltageImpl().probe
    )
}

struct BarnLocator {
    let locate: (_ seed: [String: Any]) async throws -> String
    
    static let live = BarnLocator(
        locate: HTTPBarnLocatorImpl().locate
    )
}

struct ConsentBeacon {
    let request: () -> AsyncStream<Bool>
    let arm: () -> Void
    
    static let live: ConsentBeacon = {
        let impl = NotificationConsentImpl()
        return ConsentBeacon(
            request: impl.request,
            arm: impl.arm
        )
    }()
}

struct CoopEnvironment {
    let vault: CoopVault
    let voltage: VoltageProbe
    let locator: BarnLocator
    let consent: ConsentBeacon
    
    static let live: CoopEnvironment = {
        CoopEnvironment(
            vault: SQLiteCoopVault(),
            voltage: .live,
            locator: .live,
            consent: .live
        )
    }()
}
