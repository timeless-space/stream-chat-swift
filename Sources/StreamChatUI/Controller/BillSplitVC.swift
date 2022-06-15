//
//  BillSplitVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 09/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public class BillSplitVC: UIViewController {
    // MARK: - Outlet
    @IBOutlet private weak var selectUserButton: UIButton!
    @IBOutlet private weak var selectedUsersView: UIView!
    @IBOutlet private weak var usersCollectionView: CollectionViewGroupUserList!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var editButton: UIButton!

    // MARK: - Variables
    public var channelController: ChatChannelController?
    public var callbackSelectFriend:(() -> Void)?
    public var selectedUsers = [ChatUser]()

    // MARK: - View Life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // setup ui
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        updateUI(with: selectedUsers)
    }

    public func updateUI(with users: [ChatUser]) {
        selectedUsers = users
        setupSelectedUserContainerView()
        setupSelectUserButton()
        setupNextButton()
        setupEditButton()
    }

    public func setupSelectUserButton() {
        selectUserButton.isHidden = !selectedUsers.isEmpty
    }

    public func setupNextButton() {
        nextButton.isHidden = selectedUsers.isEmpty
    }

    public func setupEditButton() {
        editButton.isHidden = selectedUsers.isEmpty
    }

    private func setupSelectedUserContainerView() {
        usersCollectionView.callbackSelectedUser = { [weak self] users in
            guard let weakSelf = self else { return }
            let filteredData = users.map { $0.id }
            weakSelf.selectedUsers = weakSelf.selectedUsers
                .filter { filteredData.contains($0.id) }
            if users.isEmpty {
                weakSelf.setupUI()
            }
        }
        usersCollectionView.isRemoveButtonHidden = false
        usersCollectionView.setupUsers(users: selectedUsers)
        selectedUsersView.isHidden = selectedUsers.isEmpty
    }

    // MARK: - Action
    @IBAction func selectFriendAction(_ sender: UIButton) {
        callbackSelectFriend?()
    }
}
