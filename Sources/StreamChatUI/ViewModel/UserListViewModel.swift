//
//  UserListViewModel.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 25/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

public class UserListViewModel: NSObject {
    
    // MARK: - VARIABLE
    public enum ChatUserLoadingState {
        case searching,searchingError, loading, loadMoreData, error, completed , none
    }
    var bCallbackDataLoadingStateUpdated: ((UserListViewModel.ChatUserLoadingState) -> Void)?
    var bCallbackDataUserList: (([ChatUser]) -> Void)?
    public lazy var dataLoadingState = UserListViewModel.ChatUserLoadingState.none {
        didSet {
            self.bCallbackDataLoadingStateUpdated?(dataLoadingState)
        }
    }
    public var searchText: String?
    public lazy var selectedUsers = [ChatUser]()
    public lazy var existingUsers = [ChatUser]()
    public lazy var filteredUsers = [ChatUser]()
    public var sortType:Em_ChatUserListFilterTypes
    private var userListController: ChatUserListController?
    private lazy var searchListController: ChatUserSearchController = {
        return ChatClient.shared.userSearchController()
    }()
    private var searchOperation: DispatchWorkItem?
    public var hasLoadedAllData: Bool = false
    private var userFetchLimit: Int = 99
    private var retryApiCount: Int = 0
    public lazy var sectionWiseUserList = [ChatUserListData]()

    // MARK: - INIT
    init(sortType: Em_ChatUserListFilterTypes) {
        self.sortType = sortType
        super.init()
    }

    // MARK: - METHOD
    public func isUserSelected(chatUser: ChatUser) -> Int? {
        return self.selectedUsers.firstIndex(where: { $0.id.lowercased() == chatUser.id.lowercased()})
    }
}
// MARK: - SORT METHODS
extension UserListViewModel {
    // TODO:  Will try improve filter user list in future
    public func sortAtoZ(filteredUsers: [ChatUser]) -> ChatUserListData {
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        var data = ChatUserListData.init(letter: "", sectionType: .noHeader)
        data.users = alphabetUsers
        data.users.append(contentsOf: otherUsers)
        return data
    }
    
    public func sortLastSeen(filteredUsers: [ChatUser]) -> ChatUserListData{
        // Online Users
        let onlineUser = filteredUsers.filter ({ $0.isOnline })
        let onlineAlphabetUsers = onlineUser.filter {( $0.name?.isFirstCharacterAlp ?? false)}.getAlphabeticallySortedUsers()
        let onlineNonAlphabetUsers = onlineUser.filter { ($0.name?.isFirstCharacterAlp ?? false) == false}.getAlphabeticallySortedUsers()
        // offline Users
        let offlineUsers = filteredUsers.filter({ $0.isOnline == false && $0.name?.isBlank == false}).sorted(by: { ($0.lastActiveAt ?? $0.userCreatedAt) > ($1.lastActiveAt ?? $1.userCreatedAt )})
        var data = ChatUserListData.init(letter: "", sectionType: .noHeader)
        data.users.append(contentsOf: onlineAlphabetUsers)
        data.users.append(contentsOf: onlineNonAlphabetUsers)
        data.users.append(contentsOf: offlineUsers)
        return data
    }
    
    public func shortByName(filteredUsers: [ChatUser]) -> [ChatUserListData] {
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        let groupByName = Dictionary(grouping: alphabetUsers) { (user) -> Substring in
            return user.name!.lowercased().prefix(1)
        }
        var data = [ChatUserListData]()
        let keys = groupByName.keys.sorted()
        keys.forEach { item  in
            data.append(ChatUserListData.init(letter: String(item), sectionType: .alphabetHeader, users: groupByName[item] ?? []))
        }
        if !otherUsers.isEmpty {
            data.append(ChatUserListData.init(letter: "#", sectionType: .alphabetHeader, users: otherUsers))
        }
        return data
    }
}
// MARK: - GET STREAM API
extension UserListViewModel {
    public func searchDataUsing(searchString: String?) {
        self.searchText = searchString
        if self.dataLoadingState != .searching {
            self.dataLoadingState = .searching
        }
        searchOperation?.cancel()
        searchOperation = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.searchUser(with: searchString)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: searchOperation!)
    }
    
    private func searchUser(with name: String?) {
        if let strName = name, strName.isEmpty == false {
            if strName.containsEmoji  || strName.isBlank {
                Snackbar.show(text: "Please enter valid name")
                self.dataLoadingState = .searchingError
                return
            }
            var newQuery = UserListQuery.init(
                filter: .and([
                    .autocomplete(.name, text: strName),
                    .exists(.lastActiveAt),
                    .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
                ]),
                sort: [],
                pageSize: 30)
            searchListController.search(query: newQuery) { [weak self] error in
                guard let weakSelf = self else { return }
                if let error = error {
                    weakSelf.dataLoadingState = .searchingError
                } else {
                    let filterData = weakSelf.getFilteredData(users: weakSelf.searchListController.users)
                    weakSelf.bCallbackDataUserList?(filterData)
                    weakSelf.dataLoadingState = .completed
                }
            }
        }
    }
    
    open func refreshUserList(_ fetchMoreData: Bool = false) {
        hasLoadedAllData = false
        retryApiCount = 0
        searchText = nil
        fetchUserList(fetchMoreData)
    }
    
    open func fetchUserList(_ fetchMoreData: Bool = false) {
        if hasLoadedAllData {
            return
        }
        guard searchText == nil else {
            return
        }
        searchOperation?.cancel()
        if dataLoadingState == .loading || dataLoadingState == .loadMoreData {
            return
        }
        if dataLoadingState != .loading && fetchMoreData == false {
            dataLoadingState = .loading
        }
        if fetchMoreData {
            dataLoadingState = .loadMoreData
        }
        callStreamChatUserListApi(fetchMoreData)
    }

    private func callStreamChatUserListApi(_ fetchMoreData: Bool) {
        if userListController == nil {
            var userQuery: UserListQuery?
            if sortType == .sortByAtoZ {
                userQuery = UserListQuery(sort: [.init(key: .name, isAscending: true)], pageSize: userFetchLimit)
            } else {
                userQuery = UserListQuery(sort: [.init(key: .lastActivityAt, isAscending: false)], pageSize: userFetchLimit)
            }
            userQuery?.filter = .and([
                .exists(.id),
                .exists(.lastActiveAt),
                .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
                .lessOrEqual(.lastActiveAt, than: Date()),
            ])
            userQuery?.shouldBeUpdatedInBackground = false
            self.userListController = ChatClient.shared.userListController(query: userQuery ?? .init())
        }
        if fetchMoreData {
            userListController?.loadNextUsers(limit: userFetchLimit, completion: { [weak self] (error,paginationStatus) in
                guard let weakSelf = self else { return }
                weakSelf.hasLoadedAllData = paginationStatus
                if error == nil {
                    DispatchQueue.main.async {
                        weakSelf.processUserList()
                    }
                } else {
                    weakSelf.dataLoadingState = weakSelf.searchText == nil ? .error : .searchingError
                }
            })
        } else {
            userListController?.synchronize { [weak self] error in
                guard let weakSelf = self else { return }
                if error == nil {
                    DispatchQueue.main.async {
                        weakSelf.processUserList()
                    }
                } else {
                    weakSelf.dataLoadingState = .error
                }
            }
        }
    }

    private func processUserList() {
        let filterData = getFilteredData(users: userListController?.users ?? [])
        // checking sorting type , if it sortByAtoZ , then we will skip no alphabetUsers users
        guard sortType == .sortByAtoZ else {
            bCallbackDataUserList?(filterData)
            dataLoadingState = .completed
            return
        }
        let alphabetUsers = filterData.filter({ $0.name?.isFirstCharacterAlp == true })
        guard alphabetUsers.count == 0 else {
            bCallbackDataUserList?(alphabetUsers)
            dataLoadingState = .completed
            return
        }
        guard retryApiCount <= 4 else {
            bCallbackDataUserList?(filterData)
            dataLoadingState = .completed
            return
        }
        retryApiCount += 1
        callStreamChatUserListApi(true)
    }

    open func getUsers() -> [ChatUser] {
        if let strName = searchText, strName.isBlank == false {
            return getFilteredData(users: searchListController.users)
        } else  {
            return getFilteredData(users: userListController?.users ?? [])
        }
    }
    
    private func getFilteredData(users: LazyCachedMapCollection<ChatUser>) -> [ChatUser] {
        return users.filter { $0.name?.isEmpty == false && $0.id.isEmpty == false && $0.id != ChatClient.shared.currentUserId ?? ""}
    }
}

// Array extension for Chat user name wise sort
extension Array where Element == ChatUser {
    public  func getAlphabeticallySortedUsers() -> [ChatUser] {
        return sorted{ ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == ComparisonResult.orderedAscending}
    }
}
