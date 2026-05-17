import Foundation

infix operator |> : AdditionPrecedence

func |> <In, Out>(value: In, transform: (In) async throws -> Out) async rethrows -> Out {
    return try await transform(value)
}

struct Operator<In, Out> {
    let label: String
    let transform: (In) async throws -> Out
    
    func callAsFunction(_ input: In) async throws -> Out {
        return try await transform(input)
    }
    
    /// Композиция двух операторов: self.then(other) → новый Operator<In, Next>
    func then<Next>(_ next: Operator<Out, Next>) -> Operator<In, Next> {
        Operator<In, Next>(label: "\(label) → \(next.label)") { input in
            let intermediate = try await self.transform(input)
            return try await next.transform(intermediate)
        }
    }
}

enum PipelineSignal {
    case continueChain(CoopState)
    case terminate(CoopOutcome)
}

struct PipelineBag {
    let state: CoopState
    let env: CoopEnvironment
    var signal: PipelineSignal
    
    func terminating(with outcome: CoopOutcome) -> PipelineBag {
        var copy = self
        copy.signal = .terminate(outcome)
        return copy
    }
    
    func continuing() -> PipelineBag {
        var copy = self
        copy.signal = .continueChain(state)
        return copy
    }
}
