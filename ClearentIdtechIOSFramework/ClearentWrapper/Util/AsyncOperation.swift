//
//  AsyncOperation.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 10.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    enum State: String {
        case waiting, ready, executing, finished, cancelled
    }

    var state: State = State.waiting {
        willSet {
            willChangeValue(forKey: State.ready.rawValue)
            willChangeValue(forKey: State.executing.rawValue)
            willChangeValue(forKey: State.finished.rawValue)
            willChangeValue(forKey: State.cancelled.rawValue)
        }
        didSet {
            switch self.state {
            case .waiting:
                assert(oldValue == .waiting, "Invalid change from \(oldValue) to \(state)")
            case .ready:
                assert(oldValue == .waiting, "Invalid change from \(oldValue) to \(state)")
            case .executing:
                assert(
                    oldValue == .ready || oldValue == .waiting,
                    "Invalid change from \(oldValue) to \(state)"
                )
            case .finished:
                assert(oldValue != .cancelled, "Invalid change from \(oldValue) to \(state)")
            case .cancelled:
                break
            }

            didChangeValue(forKey: State.cancelled.rawValue)
            didChangeValue(forKey: State.finished.rawValue)
            didChangeValue(forKey: State.executing.rawValue)
            didChangeValue(forKey: State.ready.rawValue)
        }
    }

    override var isReady: Bool {
        if state == .waiting {
            return super.isReady
        } else {
            return state == .ready
        }
    }

    override var isExecuting: Bool {
        if state == .waiting {
            return super.isExecuting
        } else {
            return state == .executing
        }
    }

    override var isFinished: Bool {
        if state == .waiting {
            return super.isFinished
        } else {
            return state == .finished
        }
    }

    override var isCancelled: Bool {
        if state == .waiting {
            return super.isCancelled
        } else {
            return state == .cancelled
        }
    }

    override var isAsynchronous: Bool { true }
}

class AsyncBlockOperation: AsyncOperation {
    public typealias Closure = (AsyncBlockOperation) -> ()

    let closure: Closure

    init(closure: @escaping Closure) {
        self.closure = closure
    }

    override func main() {
        guard !isCancelled else { return }

        closure(self)
    }
}
