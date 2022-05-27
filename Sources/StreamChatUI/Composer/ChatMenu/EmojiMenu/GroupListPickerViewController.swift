//
//  GroupListPickerViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 08/04/22.
//

import UIKit
import StreamChat
import Nuke

class GroupListPickerViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var tblMember: UITableView! {
        didSet {
            tblMember.register(TableViewCellChatUser.nib, forCellReuseIdentifier: TableViewCellChatUser.reuseId)
        }
    }

    //MARK: Variables
    var controller: ChatChannelController?
    var didSelectMember: ((ChatChannelMember) -> Void)?
    private var members = [ChatChannelMember]()
    private var currentPage : Int = 0
    private var totalCount: Int = 0
    private var isLoadingList : Bool = false
    private var channelMember: ChatChannelMemberListController?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let cid = controller?.cid else { return }
        channelMember = controller?.client.memberListController(query: .init(cid: cid))
        channelMember?.synchronize({ [weak self] error in
            guard let `self` = self else { return }
            if let error = error {
                Snackbar.show(text: "Something went wrong!", messageType: nil)
            } else {
                self.members = self.channelMember?.members.map { $0 } ?? []
                self.members.removeAll(where: { $0.id == ChatClient.shared.currentUserId })
                self.tblMember.reloadData()
            }
        })
    }
}

extension GroupListPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellChatUser.reuseId) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        cell.configGroupDetails(channelMember: members[indexPath.row], selectedImage: nil)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectMember?(members[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}

extension GroupListPickerViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return tblMember
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(self.view.bounds.height / 1.8)
    }

    var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(self.view.bounds.height)
    }

    var anchorModalToLongForm: Bool {
        return false
    }

    var showDragIndicator: Bool {
        return false
    }

    var allowsExtendedPanScrolling: Bool {
        return true
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    var cornerRadius: CGFloat {
        return 24
    }
}
