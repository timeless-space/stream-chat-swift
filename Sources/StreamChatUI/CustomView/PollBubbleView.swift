//
//  PollBubbleView.swift
//  StreamChatUI
//
//  Created by Phu Tran on 26/05/2022.
//

import SwiftUI
import StreamChat
import Nuke

@available(iOS 15.0, *)
struct PollBubbleView {
    // MARK: - Input Paramters
    var cid: ChannelId
    var question = ""
    var imageUrl = ""
    var multipleChoices = false
    var hideTally = false
    @State var answers: [AnswerRes] = []
    @State var pollVotedCount: Double = 0
    @State var orderedWallets: [OrderedWallet] = []
    var pollID = ""
    var isSender: Bool
    var isPreview = false
    var showYourFirstPoll = false

    // MARK: - Properties
    @State private var selectedAnswersID: [String] = []
    @State private var voted = false
    @State private var loadingSubmit = false
    @State private var isLoaded = false
    @State private var uiImageView = UIImageView()
    @State private var uploadedImage: UIImage?
    @State private var memberVotedURL: [String] = []
    @State private var mediaSize: CGSize?
    @State private var isGifMedia = false
    @State private var listVotedAnswer: [String] = []
    private let mediaWidth = UIScreen.main.bounds.width * 243 / 375

    // MARK: - Callback Functions
    var callBackSend: () -> Void
    var callBackEdit: () -> Void
    var callBackCancel: () -> Void
    var callBackSubmit: ([String]) -> Void
    var callBackViewResults: ([AnswerRes], Double) -> Void

    // MARK: Computed Variables
    private var enableSubmitButton: Bool {
        return voted ? true : !selectedAnswersID.isEmpty
    }

    struct AnswerRes {
        var id = ""
        var content = ""
        var pollID = ""
        var votedCount = 0
        var wallets: [AnswerWallet] = []
        var createdAt = ""
    }

    struct AnswerWallet {
        var title = ""
        var avatar = ""
        var bio = ""
        var id = ""
        var address = ""
        var verified = false
    }

    struct OrderedWallet {
        var walletAddress = ""
        var createdAt = ""
    }
}

// MARK: - Body view
@available(iOS 15.0, *)
extension PollBubbleView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if !imageUrl.isEmpty {
                    mediaView(imageUrl)
                }
                contentView
            }
            .cornerRadius(15)
            if isPreview {
                previewButtons
            }
        }
        .onAppear { onAppearHandler() }
        .onReceive(NotificationCenter.default.publisher(for: .pollUpdate)) { notification in
            onReceiveUpdatedPoll(notification)
        }
    }
}

// MARK: - Subview
@available(iOS 15.0, *)
extension PollBubbleView {
    private func mediaView(_ imageURL: String) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.black)
                .frame(width: mediaWidth, height: mediaWidth)
            ProgressView()
                .progressViewStyle(.circular)
                .opacity(!isGifMedia || uploadedImage == nil ? 1 : 0)
            if isLoaded {
                if isGifMedia, let url = URL(string: imageURL) {
                    SwiftyGifView(url: url, frame: mediaWidth)
                        .frame(width: mediaWidth, height: mediaWidth)
                } else if let uiimage = uploadedImage {
                    Image(uiImage: uiimage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: mediaWidth, height: mediaWidth)
                }
            }
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showYourFirstPoll {
                Text("YOUR FIRST POLL")
                    .tracking(-0.4)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))
                    .padding(.bottom, 2.5)
            }
            Text(question)
                .tracking(-0.2)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 1)
                .padding(.bottom, isPreview ? 10.5 : 4.5)
            if !isPreview {
                HStack(spacing: 3) {
                    Text("\(Int(pollVotedCount)) \(pollVotedCount > 1 ? "Votes" : "Vote")")
                        .tracking(-0.4)
                        .font(.system(size: 10))
                        .foregroundColor(Color.white)
                        .padding(.leading, 1)
                        .overlay(
                            ZStack {
                                if memberVotedURL.count > 0 {
                                    ForEach(0 ..< (memberVotedURL.count <= 5 ? memberVotedURL.count : 5)) { idx in
                                        ListMemberAvatar(avatarURL: memberVotedURL[idx])
                                            .zIndex(Double(-idx))
                                            .offset(x: CGFloat(idx * 12 - idx))
                                    }
                                }
                            }
                                .offset(x: 21)
                                .id("\(memberVotedURL.count)"), alignment: .trailing
                        )
                }
                .padding(.bottom, 14.5)
            }
            VStack(alignment: .leading, spacing: 17) {
                ForEach(0 ..< answers.count) { idx in
                    PollSelectLine(item: answers[idx],
                                   multipleChoices: multipleChoices,
                                   hideTally: hideTally,
                                   isPreview: isPreview,
                                   isSender: isSender,
                                   listVotedAnswer: listVotedAnswer,
                                   selectedAnswersID: $selectedAnswersID,
                                   voted: $voted,
                                   answers: $answers,
                                   pollVotedCount: $pollVotedCount)
                }
            }
            .padding(.bottom, 17)
            .disabled(voted || isPreview)
            if !isPreview {
                submitResultButton
            }
        }
        .padding(.top, 8.5)
        .padding(.bottom, isPreview ? 1 : 8.5)
        .padding(.horizontal, 12.5)
        .frame(width: mediaWidth, alignment: .leading)
        .background(isSender ? Color.blue : Color.gray.opacity(0.6))
        .background(Color.black)
    }

    struct SwiftyGifView: UIViewRepresentable {
        var url: URL
        var frame: CGFloat
        var scaleToFit = true

        func makeUIView(context: Context) -> UIView {
            let view = UIView()

            let gifImageView = UIImageView()
            gifImageView.contentMode = .scaleAspectFill
            gifImageView.translatesAutoresizingMaskIntoConstraints = false
            gifImageView.setGifFromURL(url)
            gifImageView.startAnimatingGif()

            view.addSubview(gifImageView)
            NSLayoutConstraint.activate([
                gifImageView.heightAnchor.constraint(equalTo: view.heightAnchor),
                gifImageView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            return view
        }

        func updateUIView(_ contentView: UIView, context: Context) { }
    }

    private var submitResultButton: some View {
        Button(action: {
            if voted {
                onTapViewResults()
            } else {
                onTapSubmit()
            }
        }) {
            RoundedRectangle(cornerRadius: .infinity)
                .foregroundColor(enableSubmitButton ? Color.white.opacity(0.2) : Color.black.opacity(0.25))
                .frame(width: UIScreen.main.bounds.width * 184 / 375, height: 29)
                .overlay(
                    ZStack {
                        Text("Submit Vote")
                            .tracking(-0.3)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(enableSubmitButton ? 1 : 0.5))
                            .opacity(voted ? 0 : 1)
                            .offset(x: voted ? 50 : 0)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(loadingSubmit ? 0.7 : 0.1)
                                    .opacity(loadingSubmit ? 1 : 0)
                                    .offset(x: 22), alignment: .trailing
                            )
                        Text("View Results")
                            .tracking(-0.3)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white)
                            .opacity(voted ? 1 : 0)
                            .offset(x: voted ? 0 : -50)
                    }
                    .offset(y: 0.5)
                )
                .padding(.horizontal, 16.5)
                .animation(.easeInOut(duration: 0.2), value: enableSubmitButton)
        }
        .disabled(!enableSubmitButton)
        .padding(.bottom, 4.5)
        .id("\(answers)")
    }

    private var previewButtons: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button(action: { callBackSend() }) {
                Text("Send")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue)
            }
            .padding(.trailing, 33)
            Button(action: { callBackEdit() }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.trailing, 33)
            Button(action: { callBackCancel() }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
        }
        .padding(.top, 12)
    }

    struct ListMemberAvatar: View {
        var avatarURL = ""
        @State private var avatarUIImageView = UIImageView()
        @State private var avatarUIImage: UIImage?

        var body: some View {
            if avatarUIImage == nil {
                DispatchQueue.main.async {
                    Nuke.loadImage(with: avatarURL, into: avatarUIImageView) { result in
                        switch result {
                        case .success(let imageResult):
                            avatarUIImage = imageResult.image
                        case .failure: break
                        }
                    }
                }
            }
            return Rectangle()
                .foregroundColor(Color.clear)
                .frame(width: 16.5, height: 16.5)
                .overlay(
                    ZStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                            .opacity(avatarUIImage == nil ? 1 : 0)
                        if avatarUIImage != nil {
                            Image(uiImage: avatarUIImage!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 16.5, height: 16.5)
                        }
                    }
                )
                .cornerRadius(.infinity)
        }
    }

    private func memberAvatar(_ avatarURL: String) -> some View {
        AsyncImage(url: URL(string: avatarURL)) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.black
        }
        .frame(width: 16.5, height: 16.5)
        .cornerRadius(.infinity)
    }
}

// MARK: - Methods
@available(iOS 15.0, *)
extension PollBubbleView {
    private func onAppearHandler() {
        if !imageUrl.isEmpty, !isGifMedia, uploadedImage == nil {
            let pathExtension = imageUrl.components(separatedBy: "?")
            let path = pathExtension.count > 0 ? pathExtension[0] : ""
            let mediaType = path.split(separator: ".").last ?? ""
            if mediaType == "gif" {
                isGifMedia = true
            } else {
                Nuke.loadImage(with: imageUrl, into: uiImageView) { result in
                    switch result {
                    case .success(let imageViewResult):
                        uploadedImage = imageViewResult.image
                    case .failure: break
                    }
                }
            }
        }
        if let userInfo = PollBubble.callback?(pollID) {
            setDataFromUserInfo(userInfo)
        } else {
            var userInfo = [String: Any]()
            userInfo["group_id"] = cid.description
            userInfo["poll_id"] = pollID
            NotificationCenter.default.post(name: .getPollData, object: nil, userInfo: userInfo)
        }
    }

    private func onReceiveUpdatedPoll(_ notification: NotificationCenter.Publisher.Output) {
        if let userInfo = notification.userInfo {
            setDataFromUserInfo(userInfo, updatedPoll: true)
        }
    }

    private func setDataFromUserInfo(_ userInfo: [AnyHashable: Any], updatedPoll: Bool = false) {
        withAnimation(.easeInOut(duration: updatedPoll ? 0.2 : 0)) {
            loadingSubmit = false
        }
        if cid.description == (userInfo["group_id"] as? String ?? ""),
            pollID == (userInfo["poll_id"] as? String ?? "") {
            withAnimation(.easeInOut(duration: updatedPoll ? 0.2 : 0)) {
                voted = userInfo["voted"] as? Bool ?? false
            }
            listVotedAnswer = userInfo["vote_for"] as? [String] ?? []
            pollVotedCount = userInfo["poll_voted_count"] as? Double ?? 0

            self.answers.removeAll()
            let answers = userInfo["answers"] as? [[String: Any]] ?? []
            answers.forEach { answer in
                var wallets: [AnswerWallet] = []
                let walletItems = answer["wallets"] as? [[String: Any]] ?? []
                walletItems.forEach { wallet in
                    let title = wallet["title"] as? String ?? ""
                    let avatar = wallet["avatar"] as? String ?? ""
                    let bio = wallet["bio"] as? String ?? ""
                    let id = wallet["id"] as? String ?? ""
                    let address = wallet["address"] as? String ?? ""
                    let verified = wallet["verified"] as? Bool ?? false
                    wallets.append(AnswerWallet(
                        title: wallet["title"] as? String ?? "",
                        avatar: wallet["avatar"] as? String ?? "",
                        bio: wallet["bio"] as? String ?? "",
                        id: wallet["id"] as? String ?? "",
                        address: wallet["address"] as? String ?? "",
                        verified: wallet["verified"] as? Bool ?? false
                    ))
                }
                self.answers.append(AnswerRes(
                    id: answer["id"] as? String ?? "",
                    content: answer["content"] as? String ?? "",
                    pollID: pollID,
                    votedCount: answer["voted_count"] as? Int ?? 0,
                    wallets: wallets,
                    createdAt: answer["created_at"] as? String ?? ""
                ))
            }
            self.orderedWallets.removeAll()
            let orderedWallets = userInfo["ordered_wallets"] as? [[String: Any]] ?? []
            orderedWallets.forEach { orderedWallet in
                self.orderedWallets.append(OrderedWallet(
                    walletAddress: orderedWallet["wallet_address"] as? String ?? "",
                    createdAt: orderedWallet["created_at"] as? String ?? ""
                ))
            }
            memberVotedURL.removeAll()
            self.orderedWallets.forEach { orderedWallet in
                if let walletImageURL = PollBubble.getWalletImageURL?(orderedWallet.walletAddress) {
                    memberVotedURL.append(walletImageURL)
                }
            }
        }
        isLoaded = true
    }

    /// Trigger when tap on "Submit" button
    private func onTapSubmit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            loadingSubmit = true
        }
        callBackSubmit(selectedAnswersID)
    }

    /// Trigger when tap on "View Results" button
    /// This "View Results" button only display after user vote a poll
    private func onTapViewResults() {
        callBackViewResults(answers, pollVotedCount)
    }
}
