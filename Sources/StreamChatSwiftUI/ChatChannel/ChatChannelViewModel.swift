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
    
    @ObservedObject var channelController: ChatChannelController.ObservableObject
    
    @Published var scrolledId: String?
    
    @Published var text = "" {
        didSet {
            if text != "" {
                channelController.controller.sendKeystrokeEvent()
            }
        }
    }
    
    @Published var showScrollToLatestButton = false
    
    @Published var currentDateString: String?
    
    @Published var typingUsers = [String]()
            
    public init(channelController: ChatChannelController) {
        self.channelController = channelController.observableObject
        self.channelController.controller.synchronize()
    }
    
    func subscribeToChannelChanges() {
        channelController.objectWillChange.sink { [weak self] in
            guard let self = self else { return }
            if !self.showScrollToLatestButton {
                self.scrollToLastMessage()
            }
        }
        .store(in: &cancellables)
        
        if let typingEvents = channelController.channel?.config.typingEventsEnabled,
           typingEvents == true {
            subscribeToTypingChanges()
        }
    }
       
    func sendMessage() {
        channelController.controller.createNewMessage(text: text) { [weak self] in
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
        if scrolledId != channelController.messages.first?.id {
            scrolledId = channelController.messages.first?.id
        }
    }
    
    func checkForNewMessages(index: Int) {
        if index < channelController.messages.count - 10 {
            return
        }

        if _loadingPreviousMessages.compareAndSwap(old: false, new: true) {
            channelController.controller.loadPreviousMessages(completion: { [weak self] _ in
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
        channelController.controller.typingUsersPublisher.sink { [weak self] users in
            guard let self = self else { return }
            self.typingUsers = users.filter { user in
                user.id != self.channelController.controller.client.currentUserId
            }.map { user in
                user.name ?? ""
            }
        }
        .store(in: &cancellables)
    }
}

extension ChatMessage: Identifiable {}
