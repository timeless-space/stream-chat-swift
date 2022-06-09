//
//  BillSplitVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 09/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class BillSplitVC: UIViewController {
    // MARK: - Outlet
    public var channelController: ChatChannelController?
    // MARK: - Variables
    var callbackSelectFriend:(() -> Void)?

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Setup

    // MARK: - Action
    @IBAction func selectFriendAction(_ sender: UIButton) {
        callbackSelectFriend?()
    }
}
