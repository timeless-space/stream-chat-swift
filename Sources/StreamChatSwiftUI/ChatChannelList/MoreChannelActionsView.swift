//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

/// Default view for the channel more actions view.
public struct MoreChannelActionsView: View {
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    
    @StateObject var viewModel: MoreChannelActionsViewModel
    var onDismiss: () -> Void
    
    public init(
        channel: ChatChannel,
        channelActions: [ChannelAction],
        onDismiss: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ViewModelsFactory.makeMoreChannelActionsViewModel(
                channel: channel,
                actions: channelActions
            )
        )
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Text(viewModel.chatName)
                    .font(fonts.bodyBold)
                
                Text(viewModel.subtitleText)
                    .font(fonts.footnote)
                    .foregroundColor(Color(colors.textLowEmphasis))
                
                memberList
                
                ForEach(viewModel.channelActions) { action in
                    VStack {
                        Divider()
                            .padding(.horizontal, -16)
                        
                        Button {
                            if action.confirmationPopup != nil {
                                viewModel.alertAction = action
                            } else {
                                action.action()
                            }
                        } label: {
                            ChannelActionItem(action: action)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .padding(.all, 8)
            .padding(.bottom, bottomSafeArea)
            .foregroundColor(Color(colors.text))
            .opacity(viewModel.alertShown ? 0 : 1)
        }
        .alert(isPresented: $viewModel.alertShown) {
            let title = viewModel.alertAction?.confirmationPopup?.title ?? ""
            let message = viewModel.alertAction?.confirmationPopup?.message ?? ""
            let buttonTitle = viewModel.alertAction?.confirmationPopup?.buttonTitle ?? ""
            
            return Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: .destructive(Text(buttonTitle)) {
                    viewModel.alertAction?.action()
                },
                secondaryButton: .cancel()
            )
        }
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            onDismiss()
        }
    }
    
    private var memberList: some View {
        Group {
            if viewModel.members.count == 1 {
                let member = viewModel.members[0]
                ChannelMemberView(
                    avatar: viewModel.image(for: member),
                    name: member.name ?? "",
                    onlineIndicatorShown: member.isOnline
                )
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(viewModel.members) { member in
                            ChannelMemberView(
                                avatar: viewModel.image(for: member),
                                name: member.name ?? "",
                                onlineIndicatorShown: member.isOnline
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }
}

/// View for the channel action item in an action list.
public struct ChannelActionItem: View {
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts

    let action: ChannelAction

    public var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: image(for: action))
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 16)
                .foregroundColor(
                    action.isDestructive ? Color(colors.alert) : Color(colors.textLowEmphasis)
                )
            
            Text(action.title)
                .font(fonts.bodyBold)
                .foregroundColor(
                    action.isDestructive ? Color(colors.alert) : Color(colors.text)
                )
            
            Spacer()
        }
        .frame(height: 40)
    }
    
    private func image(for action: ChannelAction) -> UIImage {
        let imageName = action.iconName
        
        // Check if it's in the app bundle.
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // Support for system images.
        if let image = UIImage(systemName: action.iconName) {
            return image
        }
        
        // Check if it's bundled.
        if let image = UIImage(named: imageName, in: .streamChatUI) {
            return image
        }
        
        // Default image.
        return UIImage(systemName: "photo")!
    }
}

/// View displaying channel members with image and name.
public struct ChannelMemberView: View {
    @Injected(\.fonts) var fonts
    
    let avatar: UIImage
    let name: String
    let onlineIndicatorShown: Bool
    
    let memberSize = CGSize(width: 64, height: 64)
    
    public var body: some View {
        VStack(alignment: .center) {
            ChannelAvatarView(
                avatar: avatar,
                showOnlineIndicator: onlineIndicatorShown,
                size: memberSize
            )
            
            Text(name)
                .font(fonts.footnoteBold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: memberSize.width, maxHeight: 34, alignment: .top)
        }
    }
}
