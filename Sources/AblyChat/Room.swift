import Ably

public protocol Room: AnyObject, Sendable {
    var roomID: String { get }
    var messages: any Messages { get }
    // To access this property if presence is not enabled for the room is a programmer error, and will lead to `fatalError` being called.
    var presence: any Presence { get }
    // To access this property if reactions are not enabled for the room is a programmer error, and will lead to `fatalError` being called.
    var reactions: any RoomReactions { get }
    // To access this property if typing is not enabled for the room is a programmer error, and will lead to `fatalError` being called.
    var typing: any Typing { get }
    // To access this property if occupancy is not enabled for the room is a programmer error, and will lead to `fatalError` being called.
    var occupancy: any Occupancy { get }
    var status: any RoomStatus { get }
    func attach() async throws
    func detach() async throws
    var options: RoomOptions { get }
}

internal actor DefaultRoom: Room {
    internal nonisolated let roomID: String
    internal nonisolated let options: RoomOptions
    private let chatAPI: ChatAPI
    
    private let _messages: any Messages

    // Exposed for testing.
    internal nonisolated let realtime: RealtimeClient

    internal init(realtime: RealtimeClient, chatAPI: ChatAPI, roomID: String, options: RoomOptions) async {
        self.realtime = realtime
        self.roomID = roomID
        self.options = options
        self.chatAPI = chatAPI
        
        self._messages = await DefaultMessages(
            chatAPI: chatAPI,
            realtime: realtime,
            roomID: roomID,
            clientID: realtime.clientId ?? "")
        
        channels()
//        
//        do {
//            try await attach()
//        }
//        catch {
//            print(error.localizedDescription)
//        }
    }

    public nonisolated var messages: any Messages {
        self._messages
    }

    public nonisolated var presence: any Presence {
        fatalError("Not yet implemented")
    }

    public nonisolated var reactions: any RoomReactions {
        fatalError("Not yet implemented")
    }

    public nonisolated var typing: any Typing {
        fatalError("Not yet implemented")
    }

    public nonisolated var occupancy: any Occupancy {
        fatalError("Not yet implemented")
    }

    public nonisolated var status: any RoomStatus {
        fatalError("Not yet implemented")
    }

    /// Fetches the channels that contribute to this room.
    private func channels() -> [any RealtimeChannelProtocol] {
        [
            "chatMessages",
            "typingIndicators",
            "reactions",
        ].map { suffix in
            realtime.channels.get("\(roomID)::$chat::$\(suffix)")
        }
    }

    public func attach() async throws {
        for channel in channels() {
            try await channel.attachAsync()
        }
    }

    public func detach() async throws {
        for channel in channels() {
            try await channel.detachAsync()
        }
    }
}
