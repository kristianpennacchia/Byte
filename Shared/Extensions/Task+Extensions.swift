//
//  Task+Extensions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 30/9/2022.
//  Copyright © 2022 Kristian Pennacchia. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension Task where Failure == Error {
    @discardableResult
    static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 3,
        retryDelay: TimeInterval = 1,
        operation: @Sendable @escaping (_ isLastRetry: Bool) async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0..<maxRetryCount {
                do {
                    return try await operation(false)
                } catch {
                    let oneSecond = TimeInterval(1_000_000_000)
                    let delay = UInt64(oneSecond * retryDelay)
                    try await Task<Never, Never>.sleep(nanoseconds: delay)

                    continue
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation(true)
        }
    }
}
