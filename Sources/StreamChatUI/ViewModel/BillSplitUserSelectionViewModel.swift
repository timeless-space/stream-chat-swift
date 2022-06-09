//
//  BillSplitUserSelectionViewModel.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 09/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public class BillSplitUserSelectionViewModel: NSObject {

    public var channelController: ChatChannelController?
    public var chatMemberController: ChatChannelMemberListController?
    public var sectionWiseList: [BillSplitUserSelectionVC.SectionData] = []
    public var channelMembers: [ChatChannelMember] = []
    public var loadingMoreMembers: Bool = false
    private let memberPageLimit = 99
    public var reloadTable: (() -> Void)?

    typealias sectionData = BillSplitUserSelectionVC.SectionData

    public init(controller: ChatChannelController?) {
        super.init()
        channelController = controller
        initChannelMembers()
    }

    public func initChannelMembers() {
        guard let controller = channelController else { return }
        if chatMemberController == nil {
            do {
                var query = try ChannelMemberListQuery(cid: .init(cid: controller.cid?.description ?? ""))
                query.pagination = Pagination(pageSize: memberPageLimit)
                chatMemberController = try ChatClient.shared.memberListController(
                    query: query)
            } catch {}
        }
        chatMemberController?.synchronize { [weak self] error in
            guard let self = self else { return }
            self.sortChannelMembers()
        }
    }

    public func loadMoreMembers() {
        chatMemberController?.loadNextMembers(limit: memberPageLimit, completion: { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.sortChannelMembers()
            weakSelf.loadingMoreMembers = false
        })
    }
    
    private func sortChannelMembers() {
        guard let memberController = chatMemberController else {
            return
        }
        let nonNilUsers = (memberController.members ?? []).filter({ $0.id != nil && $0.name?.isBlank == false })
        let filteredUsers = nonNilUsers.filter({ $0.memberRole != .owner })
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        channelMembers.append(contentsOf: alphabetUsers)
        channelMembers.append(contentsOf: otherUsers)
        let groupByName = Dictionary(grouping: alphabetUsers) { (user) -> Substring in
            return user.name!.lowercased().prefix(1)
        }
        sectionWiseList = [sectionData]()
        let keys = groupByName.keys.sorted()
        keys.forEach { item  in
            sectionWiseList.append(sectionData.init(letter: String(item),
                                                    users: groupByName[item] ?? []))
        }
        if !otherUsers.isEmpty {
            sectionWiseList.append(sectionData.init(letter: "#",
                                                    users: otherUsers))
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.reloadTable?()
        }
    }
}
