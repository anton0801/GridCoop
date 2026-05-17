import Foundation

@propertyWrapper
final class Synchronized<Value> {
    private var storage: Value
    private let lock = NSRecursiveLock()
    
    var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storage = newValue
        }
    }
    
    init(wrappedValue: Value) {
        self.storage = wrappedValue
    }
    
    func mutate(_ transform: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&storage)
    }
}

final class CoopState {
    
    @Synchronized var crops: [String: String] = [:]
    @Synchronized var furrows: [String: String] = [:]
    @Synchronized var barnURL: String? = nil
    @Synchronized var barnMode: String? = nil
    @Synchronized var untilled: Bool = true
    @Synchronized var sealed: Bool = false
    @Synchronized var consentSown: Bool = false
    @Synchronized var consentFallow: Bool = false
    @Synchronized var consentTilledAt: Date? = nil
    
    // MARK: - Derived
    
    var cropsReady: Bool { !crops.isEmpty }
    
    var consentRipe: Bool {
        guard !consentSown && !consentFallow else { return false }
        if let date = consentTilledAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    // MARK: - Hydrate
    
    func hydrate(from bundle: CoopBundle) {
        crops = bundle.crops
        furrows = bundle.furrows
        barnURL = bundle.barnURL
        barnMode = bundle.barnMode
        untilled = bundle.untilled
        consentSown = bundle.consentSown
        consentFallow = bundle.consentFallow
        consentTilledAt = bundle.consentTilledAt
    }
}
