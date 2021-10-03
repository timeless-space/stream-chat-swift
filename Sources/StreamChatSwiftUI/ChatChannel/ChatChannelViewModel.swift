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
                self.currentDateString = nil
                return
            }

            self.currentDateString = messageListDateOverlay.string(from: currentDate)
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
    
    @Published var text = ""
    
    @Published var showScrollToLatestButton = false
    
    @Published var currentDateString: String?
        
    public init(channel: ChatChannelController.ObservableObject) {
        self.channel = channel
        
    }
    
    func subscribeToChannelChanges() {
        self.channel.objectWillChange.sink { [weak self] in
            guard let self = self else { return }
            if !self.showScrollToLatestButton {
                self.scrollToLastMessage()
            }
        }
        .store(in: &cancellables)
    }
    
    func sendMessage() {
        channel.controller.createNewMessage(text: text) { [weak self] in
            switch $0 {
            case .success(let response):
                print(response)
                self?.scrollToLastMessage()
            case .failure(let error):
                print(error)
            }
        }
        
        self.text = ""
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
        self.currentDate = lastDate
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: false,
            block: { [weak self] timer in
            self?.currentDate = nil
        })
    }
    
}

extension ChatMessage: Identifiable {}
