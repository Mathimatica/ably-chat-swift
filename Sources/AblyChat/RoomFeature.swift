import Ably

/// The features offered by a chat room.
internal enum RoomFeature {
    case messages
    case presence
    case reactions
    case occupancy
    case typing

    internal func channelNameForRoomID(_ roomID: String) -> String {
        "\(roomID)::$chat::$\(channelNameSuffix)"
    }

    private var channelNameSuffix: String {
        switch self {
        case .messages, .presence, .occupancy:
            // (CHA-M1) Chat messages for a Room are sent on a corresponding realtime channel <roomId>::$chat::$chatMessages. For example, if your room id is my-room then the messages channel will be my-room::$chat::$chatMessages.
            // (CHA-PR1) Presence for a Room is exposed on the realtime channel used for chat messages, in the format <roomId>::$chat::$chatMessages. For example, if your room id is my-room then the presence channel will be my-room::$chat::$chatMessages.
            // (CHA-O1) Occupancy for a room is exposed on the realtime channel used for chat messages, in the format <roomId>::$chat::$chatMessages. For example, if your room id is my-room then the presence channel will be my-room::$chat::$chatMessages.
            "chatMessages"
        case .reactions:
            // (CHA-ER1) Reactions for a Room are sent on a corresponding realtime channel <roomId>::$chat::$reactions. For example, if your room id is my-room then the reactions channel will be my-room::$chat::$reactions.
            "reactions"
        case .typing:
            // (CHA-T1) Typing Indicators for a Room is exposed on a dedicated Realtime channel. These channels use the format <roomId>::$chat::$typingIndicators. For example, if your room id is my-room then the typing channel will be my-room::$chat::$typingIndicators.
            "typingIndicators"
        }
    }
}

/// Provides all of the channel-related functionality that a room feature (e.g. an implementation of ``Messages``) needs.
///
/// This mishmash exists to give a room feature access to:
///
/// - a `RealtimeChannelProtocol` object (this is the interface that our features are currently written against, as opposed to, say, `RoomLifecycleContributorChannel`)
/// - the discontinuities emitted by the room lifecycle
/// - the presence-readiness wait mechanism supplied by the room lifecycle
internal protocol FeatureChannel: Sendable, EmitsDiscontinuities {
    var channel: RealtimeChannelProtocol { get }

    /// Waits until we can perform presence operations on the contributors of this room without triggering an implicit attach.
    ///
    /// Implements the checks described by CHA-PR3d, CHA-PR3e, CHA-PR3f, and CHA-PR3g (and similar ones described by other functionality that performs contributor presence operations). Namely:
    ///
    /// - CHA-PR3d, CHA-PR10d, CHA-PR6c, CHA-T2c: If the room is in the ATTACHING status, it waits for the current ATTACH to complete and then returns. If the current ATTACH fails, then it re-throws that operation’s error.
    /// - CHA-PR3e, CHA-PR11e, CHA-PR6d, CHA-T2d: If the room is in the ATTACHED status, it returns immediately.
    /// - CHA-PR3f, CHA-PR11f, CHA-PR6e, CHA-T2e: If the room is in the DETACHED status, it throws an `ARTErrorInfo` derived from ``ChatError.presenceOperationRequiresRoomAttach(feature:)``.
    /// - // CHA-PR3g, CHA-PR11g, CHA-PR6f, CHA-T2f: If the room is in any other status, it throws an `ARTErrorInfo` derived from ``ChatError.presenceOperationDisallowedForCurrentRoomStatus(feature:)``.
    ///
    /// - Parameters:
    ///   - requester: The room feature that wishes to perform a presence operation. This is only used for customising the message of the thrown error.
    func waitToBeAbleToPerformPresenceOperations(requestedByFeature requester: RoomFeature) async throws(ARTErrorInfo)
}

internal struct DefaultFeatureChannel: FeatureChannel {
    internal var channel: RealtimeChannelProtocol
    internal var contributor: DefaultRoomLifecycleContributor
    internal var roomLifecycleManager: RoomLifecycleManager

    internal func subscribeToDiscontinuities() async -> Subscription<ARTErrorInfo> {
        await contributor.subscribeToDiscontinuities()
    }

    internal func waitToBeAbleToPerformPresenceOperations(requestedByFeature requester: RoomFeature) async throws(ARTErrorInfo) {
        try await roomLifecycleManager.waitToBeAbleToPerformPresenceOperations(requestedByFeature: requester)
    }
}
