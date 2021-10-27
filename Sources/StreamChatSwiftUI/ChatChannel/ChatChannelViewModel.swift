//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

public class ChatChannelViewModel: ObservableObject, ChatChannelControllerDelegate {
    @Injected(\.chatClient) var chatClient
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var currentDate: Date? {
        didSet {
            guard showScrollToLatestButton == true, let currentDate = currentDate else {
                currentDateString = nil
                return
            }
            currentDateString = messageListDateOverlay.string(from: currentDate)
        }
    }
    
    private let messageListDateOverlay: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMMdd")
        df.locale = .autoupdatingCurrent
        return df
    }()
    
    @Atomic private var loadingPreviousMessages: Bool = false
    
    private var channelController: ChatChannelController
    
    @Published var scrolledId: String?
    @Published var text = "" {
        didSet {
            if text != "" {
                channelController.sendKeystrokeEvent()
            }
        }
    }

    @Published var showScrollToLatestButton = false
    @Published var currentDateString: String?
    @Published var typingUsers = [String]()
    @Published var messages = LazyCachedMapCollection<ChatMessage>()
    
    var channel: ChatChannel {
        channelController.channel!
    }
            
    public init(channelController: ChatChannelController) {
        self.channelController = channelController
        setupChannelController()
    }
    
    func subscribeToChannelChanges() {
        channelController.messagesChangesPublisher.sink { [weak self] _ in
            guard let self = self else { return }
            self.messages = self.channelController.messages
        }
        .store(in: &cancellables)

        if let typingEvents = channelController.channel?.config.typingEventsEnabled,
           typingEvents == true {
            subscribeToTypingChanges()
        }
    }
       
    // TODO: temp implementation.
    func sendMessage() {
        channelController.createNewMessage(text: text) { [weak self] in
            switch $0 {
            case let .success(response):
                print(response)
                self?.scrollToLastMessage()
            case let .failure(error):
                print(error)
            }
        }
        
        text = ""
    }
    
    func scrollToLastMessage() {
        if scrolledId != messages.first?.id {
            scrolledId = messages.first?.id
        }
    }
    
    func handleMessageAppear(index: Int) {
        checkForNewMessages(index: index)
        save(lastDate: messages[index].createdAt)
    }
    
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        messages = channelController.messages
        if !showScrollToLatestButton {
            scrollToLastMessage()
        }
    }
    
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        messages = channelController.messages
    }
    
    // TODO: temp implementation
    func addReaction(to message: ChatMessage) {
        guard let cId = message.cid else { return }
        
        let messageController = chatClient.messageController(
            cid: cId, messageId: message.id
        )
        
        let reaction: MessageReactionType = "love"
        messageController.addReaction(reaction)
    }
    
    // MARK: - private
    
    private func setupChannelController() {
        channelController.delegate = self
        channelController.synchronize()
        messages = channelController.messages
    }
    
    private func checkForNewMessages(index: Int) {
        if index < channelController.messages.count - 10 {
            return
        }

        if _loadingPreviousMessages.compareAndSwap(old: false, new: true) {
            channelController.loadPreviousMessages(completion: { [weak self] _ in
                guard let self = self else { return }
                self.loadingPreviousMessages = false
            })
        }
    }
    
    private func save(lastDate: Date) {
        currentDate = lastDate
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: false,
            block: { [weak self] _ in
                self?.currentDate = nil
            }
        )
    }
    
    private func subscribeToTypingChanges() {
        channelController.typingUsersPublisher.sink { [weak self] users in
            guard let self = self else { return }
            self.typingUsers = users.filter { user in
                user.id != self.channelController.client.currentUserId
            }.map { user in
                user.name ?? ""
            }
        }
        .store(in: &cancellables)
    }
}

extension ChatMessage: Identifiable {}
