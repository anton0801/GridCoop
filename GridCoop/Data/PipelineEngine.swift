import Foundation
import Combine

@MainActor
final class PipelineEngine {
    
    let state: CoopState
    
    private let outcomeSubject = PassthroughSubject<CoopOutcome, Never>()
    var outcomePublisher: AnyPublisher<CoopOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    private let env: CoopEnvironment
    
    init(env: CoopEnvironment = .live) {
        self.env = env
        self.state = CoopState()
    }
    
    func warmUp() {
        let bundle = env.vault.defrost()
        state.hydrate(from: bundle)
    }
    
    func ingestCrops(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.crops = mapped
        env.vault.stashCrops(mapped)
    }
    
    func ingestFurrows(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.furrows = mapped
        env.vault.stashFurrows(mapped)
    }
    
    func cultivate() async {
        guard !sequenceCompleted else { return }
        
        let pushOp    = makePushShortCircuitOperator()
        let voltageOp = makeVoltageOperator()
        let locateOp  = makeLocateBarnOperator()
        
        let pipeline = pushOp.then(voltageOp).then(locateOp)
        
        let initialBag = PipelineBag(
            state: state,
            env: env,
            signal: .continueChain(state)
        )
        
        do {
            let finalBag = try await initialBag |> pipeline.transform
            
            switch finalBag.signal {
            case .continueChain:
                break
            case .terminate(let outcome):
                sequenceCompleted = true
                outcomeSubject.send(outcome)
            }
        } catch let err as CoopError {
            sequenceCompleted = true
            outcomeSubject.send(.retreatToYard)
        } catch {
            sequenceCompleted = true
            outcomeSubject.send(.retreatToYard)
        }
    }
    
    func acceptConsent() async {
        let priorSown = state.consentSown
        let priorFallow = state.consentFallow
        
        var granted = false
        for await value in env.consent.request() {
            granted = value
            break
        }
        
        let now = Date()
        if granted {
            state.consentSown = true
            state.consentFallow = false
            state.consentTilledAt = now
            env.consent.arm()
        } else {
            state.consentSown = false
            state.consentFallow = true
            state.consentTilledAt = now
        }
        
        _ = priorSown; _ = priorFallow
        env.vault.stashConsent(sown: granted, fallow: !granted, at: now)
        outcomeSubject.send(.enterBarn)
    }
    
    func deferConsent() {
        let now = Date()
        state.consentTilledAt = now
        env.vault.stashConsent(sown: state.consentSown, fallow: state.consentFallow, at: now)
        outcomeSubject.send(.enterBarn)
    }
    
    func reportFenceCollapsed() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
    
    private func makePushShortCircuitOperator() -> Operator<PipelineBag, PipelineBag> {
        Operator(label: "pushShortCircuit") { bag in
            if case .terminate = bag.signal { return bag }
            
            guard let tempURL = UserDefaults.standard.string(forKey: CoopLegacy.pushURL),
                  !tempURL.isEmpty else {
                return bag.continuing()
            }
            
            let needsConsent = bag.state.consentRipe
            bag.state.barnURL = tempURL
            bag.state.barnMode = "Active"
            bag.state.untilled = false
            bag.state.sealed = true
            bag.env.vault.stashBarn(url: tempURL, mode: "Active")
            bag.env.vault.markTilled()
            UserDefaults.standard.removeObject(forKey: CoopLegacy.pushURL)
            
            return bag.terminating(with: needsConsent ? .requestConsent : .enterBarn)
        }
    }
    
    private func makeVoltageOperator() -> Operator<PipelineBag, PipelineBag> {
        Operator(label: "voltageProbe") { bag in
            if case .terminate = bag.signal { return bag }
            guard bag.state.cropsReady else { return bag.continuing() }
            
            let valid = try await bag.env.voltage.probe()
            if !valid { throw CoopError.voltageWilted }
            return bag.continuing()
        }
    }
    
    private func makeLocateBarnOperator() -> Operator<PipelineBag, PipelineBag> {
        Operator(label: "locateBarn") { bag in
            if case .terminate = bag.signal { return bag }
            guard bag.state.cropsReady else { return bag.continuing() }
            
            let seed = bag.state.crops.mapValues { $0 as Any }
            let url = try await bag.env.locator.locate(seed)
            
            let needsConsent = bag.state.consentRipe
            bag.state.barnURL = url
            bag.state.barnMode = "Active"
            bag.state.untilled = false
            bag.state.sealed = true
            bag.env.vault.stashBarn(url: url, mode: "Active")
            bag.env.vault.markTilled()
            UserDefaults.standard.removeObject(forKey: CoopLegacy.pushURL)
            
            return bag.terminating(with: needsConsent ? .requestConsent : .enterBarn)
        }
    }
}
