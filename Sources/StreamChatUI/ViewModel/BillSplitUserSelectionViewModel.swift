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
    private var searchListController: ChatUserSearchController?
    public var sectionWiseList: [BillSplitUserSelectionVC.SectionData] = []
    public var channelMembers: [ChatUser] = []
    public var loadingMoreMembers: Bool = false
    private let memberPageLimit = 99
    public var reloadTable: (() -> Void)?
    public var callbackSearch: ((BillSplitUserSelectionVC.SearchState) -> Void)?

    typealias sectionData = BillSplitUserSelectionVC.SectionData

    public init(controller: ChatChannelController?) {
        super.init()
        channelController = controller
        fetchChannelMembers()
    }

    public func fetchChannelMembers() {
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
            guard let memberController = self.chatMemberController else { return }
            let nonNilUsers = (memberController.members ?? [])
                .filter({ $0.id != nil && $0.name?.isBlank == false })
            self.sortChannelMembers(nonNilUsers: nonNilUsers)
        }
    }

    public func loadMoreMembers() {
        guard let memberController = chatMemberController else {
            return
        }
        memberController.loadNextMembers(limit: memberPageLimit, completion: { [weak self] _ in
            guard let weakSelf = self else { return }
            let nonNilUsers = (memberController.members ?? [])
                .filter({ $0.id != nil && $0.name?.isBlank == false })
            weakSelf.sortChannelMembers(nonNilUsers: nonNilUsers)
            weakSelf.loadingMoreMembers = false
        })
    }

    public func searchUser(with name: String) {
        let filteredData = channelMembers.filter { user in
            guard let userName = user.name else { return false }
            return userName.lowercased().contains(name.lowercased())
        }
        sortChannelMembers(nonNilUsers: filteredData)
        callbackSearch?(BillSplitUserSelectionVC.SearchState.completed)
//        guard let channelController = channelController else {
//            return
//        }
//        if searchListController == nil {
//            searchListController = ChatClient.shared.userSearchController()
//        }
//        var newQuery = UserListQuery()
//        newQuery.filter = .and([
//            .autocomplete(.name, text: name),
//            .exists(.lastActiveAt),
//            .equal(.id, to: channelController.channel!.cid.id),
//            .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
//        ])
//        searchListController?.search(query: newQuery) { [weak self] error in
//            guard let weakSelf = self else { return }
//            if let error = error {
//                weakSelf.callbackSearch?(BillSplitUserSelectionVC.SearchState.failed)
//            } else {
//                let users = weakSelf.searchListController?.users ?? []
//                let nonNilUsers = users
//                    .filter({ $0.id != nil && $0.name?.isBlank == false })
//                weakSelf.sortChannelMembers(nonNilUsers: nonNilUsers)
//                weakSelf.callbackSearch?(BillSplitUserSelectionVC.SearchState.completed)
//            }
//        }
    }

    private func sortChannelMembers(nonNilUsers: [ChatUser]) {
        let filteredUsers = nonNilUsers
            .filter({ $0.id != ChatClient.shared.currentUserId })
        let alphabetUsers = filteredUsers
            .filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }
            .sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!)
                == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers
            .filter { ($0.name?.isFirstCharacterAlp ?? false) == false }
            .sorted{ $0.id.localizedCaseInsensitiveCompare($1.id)
                == ComparisonResult.orderedAscending}
        channelMembers = alphabetUsers
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
        reloadTable?()
    }
}
