import Foundation

public typealias ReactionHeaders = Headers
public typealias ReactionMetadata = Metadata

public struct Reaction: Sendable {
    public var type: String
    public var metadata: ReactionMetadata
    public var headers: ReactionHeaders
    public var createdAt: Date
    public var clientID: String
    public var isSelf: Bool

    public init(type: String, metadata: ReactionMetadata, headers: ReactionHeaders, createdAt: Date, clientID: String, isSelf: Bool) {
        self.type = type
        self.metadata = metadata
        self.headers = headers
        self.createdAt = createdAt
        self.clientID = clientID
        self.isSelf = isSelf
    }
}
