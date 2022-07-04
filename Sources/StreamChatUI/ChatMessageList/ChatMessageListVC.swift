//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import SafariServices

/// Controller that shows list of messages and composer together in the selected channel.
@available(iOSApplicationExtension, unavailable)
open class ChatMessageListVC: _ViewController,
    ThemeProvider,
    ChatMessageListScrollOverlayDataSource,
    ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    FileActionContentViewDelegate,
    LinkPreviewViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIGestureRecognizerDelegate {
    /// The object that acts as the data source of the message list.
    public weak var dataSource: ChatMessageListVCDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The object that acts as the delegate of the message list.
    public weak var delegate: ChatMessageListVCDelegate?

    /// The root object representing the Stream Chat.
    public var client: ChatClient!
    
    public var channelType: ChannelType {
        return dataSource?.channel(for: self)?.type ?? .messaging
    }

    /// The router object that handles navigation to other view controllers.
    open lazy var router: ChatMessageListRouter = components
        .messageListRouter
        .init(rootViewController: self)

    /// The diffing data sources are only used if iOS 13 is available and if the feature is enabled.
    internal var isDiffingEnabled: Bool {
        if #available(iOS 13.0, *) {
            return self.components._messageListDiffingEnabled
        }
        return false
    }

    /// Strong reference of the `UITableViewDiffableDataSource`.
    internal var _diffableDataSource: UITableViewDataSource?

    /// Only stored properties support being marked with @available, so we need to maintain
    /// a private _diffableDataSource property to keep the strong reference. This stored
    /// property will cast the regular table view data source to the diffing one.
    @available(iOS 13.0, *)
    internal var diffableDataSource: UITableViewDiffableDataSource<Int, ChatMessage>? {
        get { _diffableDataSource as? UITableViewDiffableDataSource }
        set { _diffableDataSource = newValue }
    }

    /// A View used to display the messages.
    open private(set) lazy var listView: ChatMessageListView = components
        .messageListView
        .init()
        .withoutAutoresizingMaskConstraints

    /// A View used to display date of currently displayed messages
    open private(set) lazy var dateOverlayView: ChatMessageListScrollOverlayView = {
        let overlay = components
            .messageListScrollOverlayView.init()
            .withoutAutoresizingMaskConstraints
        overlay.listView = listView
        overlay.dataSource = self
        return overlay
    }()

    /// A button to scroll the collection view to the bottom.
    /// Visible when there is unread message and the collection view is not at the bottom already.
    open private(set) lazy var scrollToLatestMessageButton: ScrollToLatestMessageButton = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints

    /// A Boolean value indicating wether the scroll to bottom button is visible.
    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height

        return !listView.isLastCellFullyVisible && isMoreContentThanOnePage
    }

    var viewEmptyState: UIView = UIView()
    var currentWeatherType: String = "Fahrenheit"

    open override func viewDidLoad() {
        super.viewDidLoad()
        listView.register(CryptoSentBubble.self, forCellReuseIdentifier: "CryptoSentBubble")
        listView.register(CryptoReceiveBubble.self, forCellReuseIdentifier: "CryptoReceiveBubble")
        listView.register(RedPacketSentBubble.self, forCellReuseIdentifier: "RedPacketSentBubble")
        listView.register(WalletRequestPayBubble.self, forCellReuseIdentifier: "RequestBubble")
        listView.register(RedPacketBubble.self, forCellReuseIdentifier: "RedPacketBubble")
        listView.register(ChatMessageStickerBubble.self, forCellReuseIdentifier: "ChatMessageStickerBubble")
        listView.register(.init(nibName: "AdminMessageTVCell", bundle: nil), forCellReuseIdentifier: "AdminMessageTVCell")
        listView.register(RedPacketAmountBubble.self, forCellReuseIdentifier: "RedPacketAmountBubble")
        listView.register(PollBubble.self, forCellReuseIdentifier: "PollBubble")
        listView.register(PollBubble.self, forCellReuseIdentifier: "PollSentBubble")
        listView.register(RedPacketExpired.self, forCellReuseIdentifier: "RedPacketExpired")
        listView.register(TableViewCellWallePayBubbleIncoming.nib, forCellReuseIdentifier: TableViewCellWallePayBubbleIncoming.identifier)
        listView.register(TableViewCellRedPacketDrop.nib, forCellReuseIdentifier: TableViewCellRedPacketDrop.identifier)
        listView.register(.init(nibName: "AnnouncementTableViewCell", bundle: nil), forCellReuseIdentifier: "AnnouncementTableViewCell")
        listView.register(StickerGiftBubble.self, forCellReuseIdentifier: "StickerGiftBubble")
        listView.register(GiftBubble.self, forCellReuseIdentifier: "GiftBubble")
        listView.register(GiftBubble.self, forCellReuseIdentifier: "GiftSentBubble")
        listView.register(PhotoCollectionBubble.self, forCellReuseIdentifier: "PhotoCollectionBubble")
        listView.register(AttachmentPreviewBubble.self, forCellReuseIdentifier: "AttachmentPreviewBubble")
        listView.register(WeatherCell.self, forCellReuseIdentifier: "WeatherCell")
        pausePlayVideos(isScrolled: false)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setWeatherType(_:)),
            name: .setWeatherType,
            object: nil
        )
        NotificationCenter.default.post(name: .getWeatherType, object: nil)
    }

    @objc private func setWeatherType(_ notification: NSNotification) {
        currentWeatherType = notification.userInfo?["weatherType"] as? String ?? "Fahrenheit"
    }

    /// A formatter that converts the message date to textual representation.
    /// This date formatter is used between each group message and the top overlay.
    public lazy var dateSeparatorFormatter = appearance.formatters.messageDateSeparator

    /// A boolean value that determines wether the date overlay should be displayed while scrolling.
    open var isDateOverlayEnabled: Bool {
        components.messageListDateOverlayEnabled
    }

    /// A boolean value that determines wether date separators should be shown between each message.
    open var isDateSeparatorEnabled: Bool {
        components.messageListDateSeparatorEnabled
    }
    
    override open func setUp() {
        super.setUp()
        
        components.messageLayoutOptionsResolver.config = client.config
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)

        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        listView.addGestureRecognizer(tapOnList)

        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)
        // Add a top padding to the table view so that the top message is not in the edge of the nav bar
        // Note: we use "bottom" because the table view is inverted.
        listView.contentInset = .init(top: 0, left: 0, bottom: 8, right: 0)

        view.addSubview(scrollToLatestMessageButton)
        listView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -6).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        setScrollToLatestMessageButton(visible: false, animated: false)

        if isDateOverlayEnabled {
            view.addSubview(dateOverlayView)
            NSLayoutConstraint.activate([
                dateOverlayView.centerXAnchor.pin(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                dateOverlayView.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor)
            ])
            dateOverlayView.isHidden = true
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = appearance.colorPalette.chatViewBackground
        
        listView.backgroundColor = appearance.colorPalette.chatViewBackground
    }

    override open func updateContent() {
        super.updateContent()

        listView.delegate = self

        if #available(iOS 13.0, *), isDiffingEnabled {
            setupDiffableDataSource(for: listView)
        } else {
            listView.dataSource = self
            listView.reloadData()
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()
    }
    
    /// Returns layout options for the message on given `indexPath`.
    ///
    /// Layout options are used to determine the layout of the message.
    /// By default there is one message with all possible layout and layout options
    /// determines which parts of the message are visible for the given message.
    open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        dataSource?.chatMessageListVC(self, messageLayoutOptionsAt: indexPath) ?? .init()
    }

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        components.messageContentView
    }

    /// Returns the attachment view injector for the message at given `indexPath`
    open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> AttachmentViewInjector.Type? {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return nil
        }

        return components.attachmentViewCatalog.attachmentViewInjectorClassFor(
            message: message,
            components: components
        )
    }
    
    /// Set the visibility of `scrollToLatestMessageButton`.
    open func setScrollToLatestMessageButton(visible: Bool, animated: Bool = true) {
        if visible { scrollToLatestMessageButton.isVisible = true }
        Animate(isAnimated: animated, {
            self.scrollToLatestMessageButton.alpha = visible ? 1 : 0
        }, completion: { _ in
            if !visible { self.scrollToLatestMessageButton.isVisible = false }
        })
    }
    
    /// Action for `scrollToLatestMessageButton` that scroll to most recent message.
    @objc open func scrollToLatestMessage() {
        scrollToMostRecentMessage()
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToMostRecentMessage(animated: animated)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        if #available(iOS 13.0, *), isDiffingEnabled {
            updateMessagesSnapshot(with: changes, completion: completion)
        } else {
            listView.updateMessages(with: changes, completion: completion)
        }
    }

    /// Handles tap action on the table view.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.chatMessageListVC(self, didTapOnMessageListView: listView, with: gesture)
        view.endEditing(true)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let indexPath = listView.indexPathForRow(at: location)
        else { return }
        didSelectMessageCell(at: indexPath)
    }

    /// The message cell was select and should show the available message actions.
    /// - Parameter indexPath: The index path that the message was selected.
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true,
            let cid = message.cid
        else { return }

        let messageController = client.messageController(
            cid: cid,
            messageId: message.id
        )

        let actionsController = components.messageActionsVC.init()
        actionsController.messageController = messageController
        actionsController.channelConfig = dataSource?.channel(for: self)?.config
        actionsController.delegate = self

        let reactionsController: ChatMessageReactionsPickerVC? = {
            guard message.localState == nil else { return nil }
            guard dataSource?.channel(for: self)?.config.reactionsEnabled == true else {
                return nil
            }

            let controller = components.reactionPickerVC.init()
            controller.messageController = messageController
            return controller
        }()
        router.showMessageActionsPopUp(
            messageContentView: messageContentView,
            messageActionsController: actionsController,
            messageReactionsController: reactionsController
        )
    }

    /// Opens thread detail for given `MessageId`.
    open func showThread(messageId: MessageId) {
        guard let cid = dataSource?.channel(for: self)?.cid else { log.error("Channel is not available"); return }
        router.showThread(
            messageId: messageId,
            cid: cid,
            client: client
        )
    }

    /// Check if the current message being displayed should show the date separator.
    /// - Parameters:
    ///   - message: The message being displayed.
    ///   - indexPath: The indexPath of the message.
    /// - Returns: A Boolean value depending if it should show the date separator or not.
    func shouldShowDateSeparator(forMessage message: ChatMessage, at indexPath: IndexPath) -> Bool {
        guard isDateSeparatorEnabled else {
            return false
        }
        
        let previousIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        guard let previousMessage = dataSource?.chatMessageListVC(self, messageAt: previousIndexPath) else {
            // If previous message doesn't exist show the separator as well.
            return true
        }
        
        // Only show the separator if the previous message has a different day.
        let isDifferentDay = !Calendar.current.isDate(
            message.createdAt,
            equalTo: previousMessage.createdAt,
            toGranularity: .day
        )
        return isDifferentDay
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        pausePlayVideos(isScrolled: true)
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)
        let currentUserId = ChatClient.shared.currentUserId
        let isMessageFromCurrentUser = message?.author.id == currentUserId
        if channelType == .announcement {
            guard let cell = listView.dequeueReusableCell(
                withIdentifier: "AnnouncementTableViewCell",
                for: indexPath) as? AnnouncementTableViewCell else {
                    return UITableViewCell()
                }
            cell.delegate = self
            cell.cacheVideoThumbnail = components.cacheVideoThumbnail
            cell.message = message
            cell.configureCell(message)
            cell.transform = .mirrorY
            return cell
        } else {
            if isOneWalletCell(message) {
                if isMessageFromCurrentUser {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "CryptoSentBubble",
                        for: indexPath) as? CryptoSentBubble else {
                            return UITableViewCell()
                        }
                    cell.options = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.configData()
                    cell.blockExpAction = { [weak self] blockExpUrl in
                        let svc = SFSafariViewController(url: blockExpUrl)
                        let nav = UINavigationController(rootViewController: svc)
                        nav.isNavigationBarHidden = true
                        UIApplication.shared.keyWindow?.rootViewController?.present(nav, animated: true, completion: nil)
                    }
                    return cell
                } else {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "CryptoReceiveBubble",
                        for: indexPath) as? CryptoReceiveBubble else {
                            return UITableViewCell()
                        }
                    cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.client = client
                    cell.configData()
                    cell.blockExpAction = { blockExpUrl in
                        let svc = SFSafariViewController(url: blockExpUrl)
                        let nav = UINavigationController(rootViewController: svc)
                        nav.isNavigationBarHidden = true
                        UIApplication.shared.keyWindow?.rootViewController?.present(nav, animated: true, completion: nil)
                    }
                    return cell
                }
            } else if isRedPacketCell(message) {
                if isMessageFromCurrentUser {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "RedPacketSentBubble",
                        for: indexPath) as? RedPacketSentBubble else {
                            return UITableViewCell()
                        }
                    cell.options = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.configData(isSender: isMessageFromCurrentUser)
                    return cell
                }
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: TableViewCellRedPacketDrop.identifier,
                    for: indexPath) as? TableViewCellRedPacketDrop else {
                        return UITableViewCell()
                    }
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.delegate = self
                cell.configData(isSender: isMessageFromCurrentUser)
                return cell
            } else if isGiftCell(message) {
                if isMessageFromCurrentUser {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "GiftBubble",
                        for: indexPath) as? GiftBubble else {
                            return UITableViewCell()
                        }
                    cell.options = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.configureCell(isSender: isMessageFromCurrentUser)
                    cell.configData()
                    return cell
                }
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "GiftSentBubble",
                    for: indexPath) as? GiftBubble else {
                        return UITableViewCell()
                    }
                cell.options = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configureCell(isSender: isMessageFromCurrentUser)
                cell.configData()
                return cell
            }
            else if isRedPacketNoPickUpCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RedPacketExpired",
                    for: indexPath) as? RedPacketExpired else {
                        return UITableViewCell()
                    }
                if let channel = dataSource?.channel(for: self) {
                    cell.channel = channel
                }
                cell.client = client
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configData(isSender: isMessageFromCurrentUser)
                return cell
            }
            else if isRedPacketExpiredCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RedPacketBubble",
                    for: indexPath) as? RedPacketBubble else {
                        return UITableViewCell()
                    }
                if let channel = dataSource?.channel(for: self) {
                    cell.channel = channel
                }
                cell.chatClient = client
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configData(isSender: isMessageFromCurrentUser, with: .EXPIRED)
                return cell
            } else if isRedPacketReceivedCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RedPacketBubble",
                    for: indexPath) as? RedPacketBubble else {
                        return UITableViewCell()
                    }
                if let channel = dataSource?.channel(for: self) {
                    cell.channel = channel
                }
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configData(isSender: isMessageFromCurrentUser, with: .RECEIVED)
                return cell
            } else if isRedPacketAmountCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "RedPacketAmountBubble",
                    for: indexPath) as? RedPacketAmountBubble else {
                        return UITableViewCell()
                    }
                cell.client = client
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configData(isSender: isMessageFromCurrentUser)
                cell.blockExpAction = { blockExpUrl in
                    let svc = SFSafariViewController(url: blockExpUrl)
                    let nav = UINavigationController(rootViewController: svc)
                    nav.isNavigationBarHidden = true
                    UIApplication.shared.keyWindow?.rootViewController?.present(nav, animated: true, completion: nil)
                }
                return cell
            } else if isWalletRequestPayCell(message) {
                if isMessageFromCurrentUser {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "RequestBubble",
                        for: indexPath) as? WalletRequestPayBubble else {
                            return UITableViewCell()
                        }
                    if let channel = dataSource?.channel(for: self) {
                        cell.channelId = channel.cid
                    }
                    cell.isSender = isMessageFromCurrentUser
                    cell.client = client
                    cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.configData(isSender: isMessageFromCurrentUser)
                    return cell
                }
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: TableViewCellWallePayBubbleIncoming.identifier,
                    for: indexPath) as? TableViewCellWallePayBubbleIncoming else {
                        return UITableViewCell()
                    }
                cell.client = client
                cell.channel = dataSource?.channel(for: self)
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.configureCell(isSender: isMessageFromCurrentUser)
                cell.configData()
                return cell
            } else if let message = message, message.isAdminMessage() {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "AdminMessageTVCell",
                    for: indexPath) as? AdminMessageTVCell else {
                        return UITableViewCell()
                    }
                let messagesCont = dataSource?.numberOfMessages(in: self) ?? 0
                cell.content = message
                cell.configCell(messageCount: messagesCont)
                cell.transform = .mirrorY
                return cell
            } else if isStickerCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "ChatMessageStickerBubble",
                    for: indexPath) as? ChatMessageStickerBubble else {
                        return UITableViewCell()
                    }
                let messagesCont = dataSource?.numberOfMessages(in: self) ?? 0
                cell.content = message
                cell.chatChannel = dataSource?.channel(for: self)
                cell.contentActionDelegate = self
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.configureCell(isSender: isMessageFromCurrentUser)
                cell.transform = .mirrorY
                return cell
            } else if isStickerGiftCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "StickerGiftBubble",
                    for: indexPath) as? StickerGiftBubble else {
                        return UITableViewCell()
                    }
                if let channel = dataSource?.channel(for: self) {
                    cell.channel = channel
                }
                cell.content = message
                cell.configureCell(isSender: isMessageFromCurrentUser)
                return cell
            } else if isPollCell(message) {
                if isMessageFromCurrentUser {
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: "PollBubble",
                        for: indexPath) as? PollBubble else {
                            return UITableViewCell()
                        }
                    cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                    cell.content = message
                    cell.channel = dataSource?.channel(for: self)
                    cell.configData(isSender: isMessageFromCurrentUser)
                    return cell
                }
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "PollSentBubble",
                    for: indexPath) as? PollBubble else {
                        return UITableViewCell()
                    }
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.channel = dataSource?.channel(for: self)
                cell.configData(isSender: isMessageFromCurrentUser)
                return cell
            } else if isWeatherCell(message) {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "WeatherCell",
                    for: indexPath) as? WeatherCell else {
                        return UITableViewCell()
                    }
                cell.weatherType = currentWeatherType
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.content = message
                cell.contentActionDelegate = self
                cell.chatChannel = dataSource?.channel(for: self)
                cell.configureCell(isSender: isMessageFromCurrentUser)
                cell.transform = .mirrorY
                return cell
            } else if isFallbackMessage(message) {
                guard let extraData = message?.extraData,
                      let fallbackMessage = extraData["fallbackMessage"] else { return UITableViewCell() }
                let fallbackMessageString = fetchRawData(raw: fallbackMessage) as? String ?? ""
                let cell: ChatMessageCell = listView.dequeueReusableCell(
                    contentViewClass: cellContentClassForMessage(at: indexPath),
                    attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
                    layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
                    for: indexPath
                )
                var message = message
                message?.text = fallbackMessageString
                cell.messageContentView?.delegate = self
                cell.messageContentView?.content = message
                return cell
            } else if message?.isSinglePreview ?? false {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: AttachmentPreviewBubble.identifier,
                    for: indexPath) as? AttachmentPreviewBubble else {
                        return UITableViewCell()
                    }
                cell.content = message
                cell.delegate = self
                cell.contentActionDelegate = self
                cell.chatChannel = dataSource?.channel(for: self)
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.configureCell(isSender: isMessageFromCurrentUser)
                return cell
            } else if message?.isPhotoCollectionCell ?? false {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: "PhotoCollectionBubble",
                    for: indexPath) as? PhotoCollectionBubble else {
                        return UITableViewCell()
                    }
                cell.content = message
                cell.delegate = self
                cell.contentActionDelegate = self
                cell.chatChannel = dataSource?.channel(for: self)
                cell.layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
                cell.configureCell(isSender: isMessageFromCurrentUser)
                cell.transform = .mirrorY
                return cell
            } else {
                let cell: ChatMessageCell = listView.dequeueReusableCell(
                    contentViewClass: cellContentClassForMessage(at: indexPath),
                    attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
                    layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
                    for: indexPath
                )
                guard
                    let message = dataSource?.chatMessageListVC(self, messageAt: indexPath),
                    let channel = dataSource?.channel(for: self)
                else {
                    return cell
                }
                cell.messageContentView?.delegate = self
                cell.messageContentView?.channel = channel
                cell.messageContentView?.content = message

                cell.dateSeparatorView.isHidden = !shouldShowDateSeparator(forMessage: message, at: indexPath)
                cell.dateSeparatorView.content = dateSeparatorFormatter.format(message.createdAt)

                return cell
            }
        }
    }
    
    private func setupEmptyState() {
        viewEmptyState = UIView()
        self.view.addSubview(viewEmptyState)
        viewEmptyState.translatesAutoresizingMaskIntoConstraints = false
        viewEmptyState.backgroundColor = .clear
        viewEmptyState.translatesAutoresizingMaskIntoConstraints = false
        viewEmptyState.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)

        let imageView = UIImageView()
        imageView.image = appearance.images.chatIcon
        viewEmptyState.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 92).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 88).isActive = true
        imageView.centerXAnchor.constraint(equalTo: viewEmptyState.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: viewEmptyState.centerYAnchor).isActive = true

        let lblChat = UILabel()
        lblChat.text = "Awfully quiet in here"
        lblChat.font = .systemFont(ofSize: 18)
        lblChat.textColor = UIColor(rgb: 0x96A9C2)
        viewEmptyState.addSubview(lblChat)
        lblChat.translatesAutoresizingMaskIntoConstraints = false
        lblChat.centerXAnchor.constraint(equalTo: viewEmptyState.centerXAnchor, constant: 0).isActive = true
        lblChat.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50).isActive = true
        viewEmptyState.isUserInteractionEnabled = false
    }
    
    private func isOneWalletCell(_ message: ChatMessage?) -> Bool {
        message?.extraData.keys.contains("oneWalletTx") ?? false
    }

    private func isRedPacketCell(_ message: ChatMessage?) -> Bool {
        message?.extraData.keys.contains("redPacketPickup") ?? false
    }

    private func isStickerGiftCell(_ message: ChatMessage?) -> Bool {
        message?.extraData.keys.contains("sendStickerGift") ?? false
    }

    private func isGiftCell(_ message: ChatMessage?) -> Bool {
        guard let extraData = message?.extraData,
              let messageType = extraData["messageType"] else { return false }
        let type = fetchRawData(raw: messageType) as? String ?? ""
        return type == MessageType.giftPacket
    }

    private func isPollCell(_ message: ChatMessage?) -> Bool {
        return message?.extraData.keys.contains("poll") ?? false
    }

    private func isStickerCell(_ message: ChatMessage?) -> Bool {
        return (message?.extraData.keys.contains("stickerUrl") ?? false) || (message?.extraData.keys.contains("giphyUrl") ?? false)
    }

    private func isWeatherCell(_ message: ChatMessage?) -> Bool {
        return (message?.extraData.keys.contains("weather") ?? false)
    }

    private func isRedPacketExpiredCell(_ message: ChatMessage?) -> Bool {
        guard let extraData = message?.extraData, let redPacket = getExtraData(message: message, key: "RedPacketExpired") else {
            return false
        }
        if let userName = redPacket["highestAmountUserName"] {
            let strUserName = fetchRawData(raw: userName) as? String ?? ""
            return !strUserName.isEmpty
        } else {
            return false
        }
    }

    private func isRedPacketNoPickUpCell(_ message: ChatMessage?) -> Bool {
        guard let extraData = message?.extraData, let redPacket = getExtraData(message: message, key: "RedPacketExpired") else {
            return false
        }
        if let userName = redPacket["highestAmountUserName"] {
            let strUserName = fetchRawData(raw: userName) as? String ?? ""
            return strUserName.isEmpty
        } else {
            return false
        }
    }

    private func isRedPacketReceivedCell(_ message: ChatMessage?) -> Bool {
        message?.extraData.keys.contains("RedPacketTopAmountReceived") ?? false
    }

    private func isRedPacketAmountCell(_ message: ChatMessage?) -> Bool {
        message?.extraData.keys.contains("RedPacketOtherAmountReceived") ?? false
    }

    private func isWalletRequestPayCell(_ message: ChatMessage?) -> Bool {
        if let wallet = message?.attachments(payloadType: WalletAttachmentPayload.self).first {
            return true
        }
        return false
    }

    private func isFallbackMessage(_ message: ChatMessage?) -> Bool {
        guard let extraData = message?.extraData,
              let fallbackMessage = extraData["fallbackMessage"] else { return false }
        let message = fetchRawData(raw: fallbackMessage) as? String ?? ""
        return !message.isBlank
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegate?.chatMessageListVC(self, willDisplayMessageAt: indexPath)
        guard let announcementCell = cell as? AnnouncementTableViewCell else { return }
        announcementCell.getImageFromCache(announcementCell.message)
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ASVideoTableViewCell else { return }
        ASVideoPlayerController.sharedVideoPlayer.removeLayerFor(cell: cell)
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.chatMessageListVC(self, scrollViewDidScroll: scrollView)
        setScrollToLatestMessageButton(visible: isScrollToBottomButtonVisible)
    }

    func getExtraData(message: ChatMessage?, key: String) -> [String: RawJSON]? {
        if let extraData = message?.extraData[key] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return nil
            }
        } else {
            return nil
        }
    }

    // MARK: - ChatMessageListScrollOverlayDataSource

    open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return nil
        }

        return dateSeparatorFormatter.format(message.createdAt)
    }

    // MARK: - ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        delegate?.chatMessageListVC(self, didTapOnAction: actionItem, for: message)
    }

    open func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC) {
        UIApplication.shared.windows.last?.rootViewController?.dismiss(animated: true)
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        didSelectMessageCell(at: indexPath)
    }

    open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return log.error("IndexPath is not available")
        }

        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return log.error("DataSource not found for the message list.")
        }

        showThread(messageId: message.parentMessageId ?? message.id)
    }

    public func messageContentViewDidTapOnAvatarView(_ content: ChatMessage?) {
        avatarUserAction(content)
    }

    open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        log
            .info(
                "Tapped a quoted message. To customize the behavior, override messageContentViewDidTapOnQuotedMessage. Path: \(indexPath)"
            )
    }

    open func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        avatarUserAction(dataSource?.chatMessageListVC(self, messageAt: indexPath))
    }
    
    /// This method is triggered when delivery status indicator on the message at the given index path is tapped.
    /// - Parameter indexPath: The index path of the message cell.
    open func messageContentViewDidTapOnDeliveryStatusIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        
        log.info(
            """
            Tapped an delivery status view. To customize the behavior, override
            messageContentViewDidTapOnDeliveryStatusIndicator. Path: \(indexPath)"
            """
        )
    }

    // MARK: - GalleryContentViewDelegate

    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else { return }

        router.showGallery(
            message: message,
            initialAttachmentId: attachmentId,
            previews: previews
        )
    }

    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }

        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)

        guard let localState = message?.attachment(with: attachmentId)?.uploadingState else {
            return log.error("Failed to take an action on attachment with \(attachmentId)")
        }

        switch localState.state {
        case .uploadingFailed:
            client
                .messageController(cid: attachmentId.cid, messageId: attachmentId.messageId)
                .restartFailedAttachmentUploading(with: attachmentId)
        default:
            break
        }
    }

    // MARK: - Attachment Action Delegates

    open func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    ) {
        router.showLinkPreview(link: attachment.originalURL)
    }

    open func didTapOnAttachment(
        _ attachment: ChatMessageFileAttachment,
        at indexPath: IndexPath?
    ) {
        router.showFilePreview(fileURL: attachment.assetURL)
    }

    /// Executes the provided action on the message
    open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath),
              let cid = message.cid else {
            log.error("Failed to take to tap on attachment at indexPath: \(indexPath)")
            return
        }

        client
            .messageController(
                cid: cid,
                messageId: message.id
            )
            .dispatchEphemeralMessageAction(action)
    }

    open func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath,
              let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
              let messageContentView = cell.messageContentView else {
            return
        }

        router.showReactionsPopUp(
            messageContentView: messageContentView,
            client: client
        )
    }

    // MARK: - UIGestureRecognizerDelegate

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // To prevent the gesture recognizer consuming up the events from UIControls, we receive touch only when the view isn't a UIControl.
        !(touch.view is UIControl)
    }

    private func avatarUserAction(_ message: ChatMessage?) {
        guard let message = message,
              let channelId = message.cid,
              let controller: ChatGroupDetailsVC = ChatGroupDetailsVC.instantiateController(storyboard: .GroupChat)
        else { return }
        let channelController = ChatClient.shared.channelController(for: channelId)
        let memberController = ChatClient.shared.memberController(userId: message.author.id ?? .init(), in: channelId)
        if let user = memberController.member {
            if user.id == ChatClient.shared.currentUserId {
                return
            }
            controller.viewModel = .init(controller: channelController,
                                         channelMember: user)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

// MARK: - Backwards Compatibility DataSource Diffing

@available(iOS 13.0, *)
internal extension ChatMessageListVC {
    /// Setup the `UITableViewDiffableDataSource`.
    func setupDiffableDataSource(for listView: ChatMessageListView) {
        let diffableDataSource = UITableViewDiffableDataSource<Int, ChatMessage>(
            tableView: listView
        ) { [weak self] _, indexPath, _ -> UITableViewCell? in
            /// Re-use old `cellForRowAt` to maintain customer's customisations.
            let cell = self?.tableView(listView, cellForRowAt: indexPath)
            return cell
        }

        self.diffableDataSource = diffableDataSource
        listView.dataSource = diffableDataSource

        /// Populate the Initial messages data.
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatMessage>()
        snapshot.appendSections([0])
        snapshot.appendItems(dataSource?.messages ?? [], toSection: 0)
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Transforms an array of changes to a diffable data source snapshot.
    func updateMessagesSnapshot(with changes: [ListChange<ChatMessage>], completion: (() -> Void)?) {
        var snapshot = diffableDataSource?.snapshot() ?? NSDiffableDataSourceSnapshot<Int, ChatMessage>()

        let currentMessages: Set<ChatMessage> = Set(snapshot.itemIdentifiers)
        var updatedMessages: [ChatMessage] = []
        var insertedMessages: [(ChatMessage, row: Int)] = []
        var removedMessages: [(ChatMessage, row: Int)] = []
        var movedMessages: [(from: ChatMessage, to: ChatMessage)] = []

        var hasNewInsertions = false
        var hasInsertions = false

        changes.forEach { change in
            switch change {
            case let .insert(message, indexPath):
                hasInsertions = true
                if !hasNewInsertions {
                    hasNewInsertions = indexPath.row == 0
                }
                insertedMessages.append((message, row: indexPath.row))
            case let .update(message, _):
                // Check if it is a valid update. In rare occasions we get an update for a message which
                // is not in the scope of the current pagination, although it is in the database.
                guard currentMessages.contains(message) else { break }
                updatedMessages.append(message)
            case let .remove(message, indexPath):
                removedMessages.append((message, row: indexPath.row))
            case let .move(_, fromIndex, toIndex):
                guard let fromMessage = snapshot.itemIdentifiers[safe: fromIndex.row] else { break }
                guard let toMessage = snapshot.itemIdentifiers[safe: toIndex.row] else { break }
                movedMessages.append((from: fromMessage, to: toMessage))
            }
        }

        let sortedInsertedMessages = insertedMessages
            .sorted(by: { $0.row < $1.row })
            .map(\.0)

        if hasNewInsertions, let currentFirstMessage = snapshot.itemIdentifiers.first {
            // Insert new messages at the bottom.
            snapshot.insertItems(sortedInsertedMessages, beforeItem: currentFirstMessage)
        } else if hasInsertions, let currentLastMessage = snapshot.itemIdentifiers.last {
            // Load new messages at the top.
            snapshot.insertItems(sortedInsertedMessages, afterItem: currentLastMessage)
        } else if hasInsertions {
            snapshot.appendItems(sortedInsertedMessages)
        }

        snapshot.deleteItems(removedMessages.map(\.0))
        snapshot.reloadItems(updatedMessages)

        movedMessages.forEach {
            snapshot.moveItem($0.from, afterItem: $0.to)
            snapshot.reloadItems([$0.from, $0.to])
        }

        // The reason we call `performWithoutAnimation` and `animatingDifferences: true` at the same time
        // is because we don't want animations, but on iOS 14 calling `animatingDifferences: false`
        // is the same as calling `reloadData()`. Info: https://developer.apple.com/videos/play/wwdc2021/10252/?time=158
        UIView.performWithoutAnimation {
            diffableDataSource?.apply(snapshot, animatingDifferences: true) { [weak self] in

                let newestMessage = snapshot.itemIdentifiers.first
                if hasNewInsertions && newestMessage?.isSentByCurrentUser == true {
                    self?.listView.scrollToMostRecentMessage()
                }

                // When new message is inserted, update the previous message to hide the timestamp if needed.
                if hasNewInsertions, let previousMessage = snapshot.itemIdentifiers[safe: 1] {
                    let indexPath = IndexPath(row: 1, section: 0)
                    // The completion block from `apply()` should always be called on main thread,
                    // but on iOS 14 this doesn't seem to be the case, and it crashes.
                    DispatchQueue.main.async {
                        self?.updateMessagesSnapshot(
                            with: [.update(previousMessage, index: indexPath)],
                            completion: nil
                        )
                    }
                }

                // When there are deletions, we should update the previous message, so that we add the avatar image back.
                // Because we have an inverted list, the previous message has the same index of the deleted message after
                // the deletion has been executed.
                let previousRemovedMessages = removedMessages.compactMap { _, row -> (ChatMessage, IndexPath)? in
                    guard let message = snapshot.itemIdentifiers[safe: row] else { return nil }
                    return (message, IndexPath(row: row, section: 0))
                }
                if !previousRemovedMessages.isEmpty {
                    DispatchQueue.main.async {
                        self?.updateMessagesSnapshot(
                            with: previousRemovedMessages.map { ListChange.update($0, index: $1) },
                            completion: nil
                        )
                    }
                }

                completion?()
            }
        }
    }
    
    func pausePlayVideos(isScrolled: Bool) {
        guard channelType == .announcement else { return }
        ASVideoPlayerController.sharedVideoPlayer.pausePlayVideosFor(tableView: listView, isScrolled: isScrolled)
    }

    @objc private func handleAppDidBecomeActive() {
        guard channelType == .announcement else { return }
        ASVideoPlayerController.sharedVideoPlayer.pausePlayVideosFor(tableView: listView, appEnteredFromBackground: true, isScrolled: false)
    }
}

extension ChatMessageListVC: UIScrollViewDelegate {
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            pausePlayVideos(isScrolled: false)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pausePlayVideos(isScrolled: true)
    }
}

extension ChatMessageListVC: AnnouncementAction {
    func didSelectAnnouncement(_ message: ChatMessage?, view: AnnouncementTableViewCell) {
        guard let attachmentId = message?.firstAttachmentId, let message = message
        else { return }
        router.showGallery(
            message: message,
            initialAttachmentId: attachmentId,
            previews: [view]
        )
    }

    func didSelectAnnouncementAction(_ message: ChatMessage?) { }

    func didRefreshCell(_ cell: AnnouncementTableViewCell, _ img: UIImage) {
        guard let indexPath = listView.indexPath(for: cell),
            let visibleRows = listView.indexPathsForVisibleRows,
            visibleRows.contains(indexPath)
        else { return }
        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)
        cell.configureCell(message)
    }
}

extension ChatMessageListVC: PhotoCollectionAction {
    func didSelectAttachment(_ message: ChatMessage?, view: GalleryItemPreview, _ id: AttachmentId) {
        guard let chatMessage = message else {
            return
        }
        router.showGallery(
            message: chatMessage,
            initialAttachmentId: id,
            previews: [view]
        )
    }
}
