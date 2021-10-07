//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

public class ChatChannelViewModel: ObservableObject {
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
    
    @ObservedObject var channel: ChatChannelController.ObservableObject
    
    @Published var scrolledId: String?
    
    @Published var text = "" {
        didSet {
            if text != "" {
                channel.controller.sendKeystrokeEvent()
            }
        }
    }
    
    @Published var showScrollToLatestButton = false
    
    @Published var currentDateString: String?
    
    @Published var typingUsers = [String]()
            
    public init(channel: ChatChannelController) {
        self.channel = channel.observableObject
        self.channel.controller.synchronize()
    }
    
    func subscribeToChannelChanges() {
        channel.objectWillChange.sink { [weak self] in
            guard let self = self else { return }
            if !self.showScrollToLatestButton {
                self.scrollToLastMessage()
            }
        }
        .store(in: &cancellables)
        
        if let typingEvents = channel.channel?.config.typingEventsEnabled,
           typingEvents == true {
            subscribeToTypingChanges()
        }
    }
       
    func sendMessage() {
        channel.controller.createNewMessage(text: text) { [weak self] in
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
        if scrolledId != channel.messages.first?.id {
            scrolledId = channel.messages.first?.id
        }
    }
    
    func checkForNewMessages(index: Int) {
        if index < channel.messages.count - 10 {
            return
        }

        if _loadingPreviousMessages.compareAndSwap(old: false, new: true) {
            channel.controller.loadPreviousMessages(completion: { [weak self] _ in
                guard let self = self else { return }
                self.loadingPreviousMessages = false
            })
        }
    }
    
    func save(lastDate: Date) {
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
    
    // MARK: - private
    
    private func subscribeToTypingChanges() {
        channel.controller.typingUsersPublisher.sink { users in
            self.typingUsers = users.filter { user in
                user.id != self.channel.controller.client.currentUserId
            }.map { user in
                user.name ?? ""
            }
        }
        .store(in: &cancellables)
    }
}

extension ChatMessage: Identifiable {}
