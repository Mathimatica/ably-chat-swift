import Ably

public protocol Typing: AnyObject, Sendable, EmitsDiscontinuities {
    func subscribe(bufferingPolicy: BufferingPolicy) async -> Subscription<TypingEvent>
    func get() async throws -> Set<String>
    func start() async throws
    func stop() async throws
    var channel: RealtimeChannel { get }
}

public struct TypingEvent: Sendable {
    public var currentlyTyping: Set<String>

    public init(currentlyTyping: Set<String>) {
        self.currentlyTyping = currentlyTyping
    }
}
