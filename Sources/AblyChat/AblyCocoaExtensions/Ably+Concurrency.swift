import Ably

// This file contains extensions to ably-cocoa’s types, to make them easier to use in Swift concurrency.
// TODO: remove once we improve this experience in ably-cocoa (https://github.com/ably/ably-cocoa/issues/1967)

internal extension ARTRealtimeInstanceMethodsProtocol {
    func requestAsync(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?) async throws(ARTErrorInfo) -> ARTHTTPPaginatedResponse {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<ARTHTTPPaginatedResponse, ARTErrorInfo>, _>) in
            do {
                try request(method, path: path, params: params, body: body, headers: headers) { response, error in
                    if let error {
                        continuation.resume(returning: .failure(error))
                    } else if let response {
                        continuation.resume(returning: .success(response))
                    } else {
                        preconditionFailure("There is no error, so expected a response")
                    }
                }
            } catch {
                // This is a weird bit of API design in ably-cocoa (see https://github.com/ably/ably-cocoa/issues/2043 for fixing it); it throws an error to indicate a programmer error (it should be using exceptions). Since the type of the thrown error is NSError and not ARTErrorInfo, which would mess up our typed throw, let's not try and propagate it.
                fatalError("ably-cocoa request threw an error - this indicates a programmer error")
            }
        }.get()
    }
}

internal extension ARTRealtimeChannelProtocol {
    func attachAsync() async throws(ARTErrorInfo) {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, ARTErrorInfo>, _>) in
            attach { error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(()))
                }
            }
        }.get()
    }

    func detachAsync() async throws(ARTErrorInfo) {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, ARTErrorInfo>, _>) in
            detach { error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(()))
                }
            }
        }.get()
    }
}
