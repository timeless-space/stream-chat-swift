//
//  BillSplitUserSelectionVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 09/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public class BillSplitUserSelectionVC: UIViewController {

    public struct SectionData {
        let letter: String
        var users = [ChatChannelMember]()
    }

    // MARK: - Outlet
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var searchBarContainerView: UIView!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var selectedUsersCollectionView: UICollectionView!
    @IBOutlet private weak var lblAddedUser: UILabel!
    @IBOutlet private weak var viewAddedUserLabelContainer: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var addFriendButton: UIButton!
    @IBOutlet private weak var everyoneContainer: UIView!
    @IBOutlet private weak var everyoneImage: UIImageView!
    @IBOutlet private weak var everyoneLabel: UILabel!

    // MARK: - Variables
    public var selectedUsers = [ChatChannelMember]()
    public lazy var viewModel = BillSplitUserSelectionViewModel(controller: nil)
    public var channelController: ChatChannelController?

    // callback
    public var callbackSelectedUser: (([ChatChannelMember]) -> Void)?

    // MARK: - View Life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // UI
        setupUI()
        // callback
        viewModel.channelController = channelController
        viewModel.initChannelMembers()
        viewModel.reloadTable = { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.setupEveryoneContainerView()
            }
        }
    }

    // MARK: - Setup
    private func setupUI() {
        setupBackgroundColor()
        setupCloseButton()
        setupTitleColor()
        setupEveryoneContainerView()
        setupAddFriendButton()
        setupSearchBarView()
        setupCollectionView()
        setupTableView()
        setupSelectedUserView()
    }

    private func setupBackgroundColor() {
        self.view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
    }

    private func setupCloseButton() {
        closeButton.setImage(Appearance.default.images.closeCircle, for: .normal)
    }

    private func setupTitleColor() {
        titleLabel.setChatNavTitleColor()
    }

    private func setupSearchBarView() {
        searchBarContainerView.backgroundColor = Appearance
            .default
            .colorPalette
            .searchBarBackground
        searchBarContainerView.layer.cornerRadius = 20.0
        //searchField.delegate = self
        searchField.setAttributedPlaceHolder(placeHolder: "Search")
        //searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        searchField.tintColor = Appearance.default.colorPalette.statusColorBlue
    }

    private func setupSelectedUserView() {
        let hidden = selectedUsers.isEmpty
        guard !hidden else {
            lblAddedUser.text = ""
            viewAddedUserLabelContainer.isHidden = true
            selectedUsersCollectionView.isHidden = true
            selectedUsersCollectionView.reloadData()
            return
        }
        selectedUsersCollectionView.reloadData()
        selectedUsersCollectionView.layoutIfNeeded()
        if selectedUsers.count > 1 {
            let lastIndexPath = IndexPath(item: self.selectedUsers.count - 1,
                                          section: 0)
            selectedUsersCollectionView.scrollToItem(at: lastIndexPath,
                                                     at: .right, animated: true)
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.lblAddedUser.text = hidden ? "" : "ADDED"
            weakSelf.viewAddedUserLabelContainer.isHidden = hidden
            weakSelf.selectedUsersCollectionView.isHidden = hidden
            weakSelf.view.layoutIfNeeded()
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 88)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        selectedUsersCollectionView.isHidden = true
        selectedUsersCollectionView.dataSource = self
        selectedUsersCollectionView.delegate = self
        selectedUsersCollectionView.collectionViewLayout = layout
        viewAddedUserLabelContainer.isHidden = true
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        let headerView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 1))
        tableView.tableFooterView = headerView
        tableView.tableHeaderView = headerView
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(TableViewHeaderAlphabetSection.nib, forHeaderFooterViewReuseIdentifier: TableViewHeaderAlphabetSection.identifier)
        tableView.register(TableViewCellChatUser.nib, forCellReuseIdentifier: TableViewCellChatUser.identifier)
        // adding table view to container view
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIView.safeAreaBottom, right: 0)
        tableView.layoutMargins = .zero
    }

    private func setupAddFriendButton() {
        addFriendButton.isHidden = selectedUsers.isEmpty
        let count  = selectedUsers.count
        let strFriend = count == 1 ? "Friend" : "Friends"
        addFriendButton.setTitle("Add \(count) \(strFriend)", for: .normal)
    }

    private func setupEveryoneContainerView() {
        guard !viewModel.channelMembers.isEmpty else {
            everyoneContainer.isHidden = true
            return
        }
        everyoneContainer.isHidden = false
        let tineColor = UIColor.white.withAlphaComponent(0.6)
        let selectedImage = Appearance.default.images.checkmarkSquare
        let unSelectedImage = Appearance.default.images.square
        let image = selectedUsers.count == viewModel.channelMembers.count ?
        selectedImage : unSelectedImage
        everyoneImage.image = image
        everyoneLabel.text = "EVERYONE"
        everyoneLabel.textColor = tineColor
    }

    // MARK: - Action
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func addFriendButtonAction(_ sender: UIButton) {
        callbackSelectedUser?(selectedUsers)
        dismiss(animated: true)
    }

    @IBAction func everyoneButtonAction(_ sender: UIButton) {
        if selectedUsers.count == viewModel.channelMembers.count {
            selectedUsers = []
        } else {
            selectedUsers = viewModel.channelMembers
        }
        setupSelectedUserView()
        everyoneContainer.subviews.forEach({ $0.alpha = 1.0 })
        tableView.reloadData()
        setupEveryoneContainerView()
        setupAddFriendButton()
    }

    @IBAction func everyoneButtonActionDown(_ sender: UIButton) {
        everyoneContainer.subviews.forEach({ $0.alpha = 0.5 })
    }

    @IBAction func everyoneButtonActionExit(_ sender: UIButton) {
        everyoneContainer.subviews.forEach({ $0.alpha = 1.0 })
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension BillSplitUserSelectionVC: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionWiseList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sectionWiseList[section].users.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TableViewCellChatUser.identifier,
            for: indexPath) as? TableViewCellChatUser else {
                return UITableViewCell()
            }
        let user = viewModel.sectionWiseList[indexPath.section]
            .users[indexPath.row]
        var accessaryImage: UIImage? = nil
        if self.selectedUsers.firstIndex(where: { $0.id == user.id}) != nil {
            accessaryImage = Appearance.default.images.userSelected
        }
        cell.accessoryImageView.image = accessaryImage
        cell.config(user: user,selectedImage: accessaryImage)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let cell = tableView.cellForRow(at: indexPath) as? TableViewCellChatUser
        cell?.accessoryImageView.image = nil
        if let cell = cell {
            let selectionColor = Appearance.default.colorPalette.placeHolderBalanceBG.withAlphaComponent(0.7)
            UIView.animate(withDuration: 0.2, delay: 0, options: []) { [weak self] in
                guard let weakSelf = self else { return }
                cell.contentView.backgroundColor = selectionColor
                weakSelf.view.layoutIfNeeded()
            } completion: { [weak self] _ in
                cell.contentView.backgroundColor = .clear
            }
        }
        let user = viewModel.sectionWiseList[indexPath.section].users[indexPath.row]
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id}) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        setupSelectedUserView()
        setupEveryoneContainerView()
        setupAddFriendButton()
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.loadMoreChannels(tableView: tableView, forItemAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: TableViewHeaderAlphabetSection.identifier) as? TableViewHeaderAlphabetSection else {
            return nil
        }
        header.lblTitle.text = viewModel.sectionWiseList[section].letter.capitalized
        header.titleContainerView.layer.cornerRadius = 12.0
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20)
        return footerView
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

    open func loadMoreChannels(tableView: UITableView, forItemAt indexPath: IndexPath) {
        guard let controller = viewModel.chatMemberController,
              let totalMembers = viewModel.channelController?.channel?.memberCount,
              totalMembers > 0,
              viewModel.channelMembers.count != totalMembers  else {
                  return
              }
        if controller.state != .remoteDataFetched {
            return
        }
        guard let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last,
              indexPath.row == viewModel.channelMembers.count - 1,
              !viewModel.loadingMoreMembers else {
            return
        }
        viewModel.loadingMoreMembers = true
        viewModel.loadMoreMembers()
    }
}

// MARK: - CollectionView delegate
extension BillSplitUserSelectionVC: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedUsers.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CollectionCellSelectedMembers.reuseID,
            for: indexPath) as? CollectionCellSelectedMembers else {
            return UICollectionViewCell()
        }
        cell.configCell(user: selectedUsers[indexPath.row])
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedUsers.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        setupSelectedUserView()
        tableView.reloadData()
        setupEveryoneContainerView()
        setupAddFriendButton()
    }
}
