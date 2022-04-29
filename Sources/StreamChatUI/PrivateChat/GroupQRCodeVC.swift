//
//  GroupQRCodeVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 11/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import EFQRCode
import swiftScan
import StreamChat

class GroupQRCodeVC: UIViewController {

    // MARK: - Variables
    var strContent: String?
    var groupName: String?
    var channelController: ChatChannelController?
    var dynamicLinkUrl: URL?
    
    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var qrCodeView: UIView!
    @IBOutlet weak var imgQRCode: UIImageView!
    @IBOutlet weak var viewPreview: UIView!
    @IBOutlet weak var viewQR: UIView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Functions
    private func setupUI() {
        btnShare.isEnabled = false
        fetchDynamicLink()
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.closeCircle, for: .normal)
        generateQRCode()
        qrCodeView.layoutIfNeeded()
        qrCodeView.cornerRadius = self.qrCodeView.bounds.width / 2
        lblName.text = channelController?.channel?.name
        let shareImage = Appearance.default.images.shareImageIcon.withRenderingMode(.alwaysTemplate)
        shareImage.tinted(with: .white)
        btnShare.tintColor = .white
        btnShare.setImage(shareImage, for: .normal)
        viewPreview.backgroundColor = Appearance.default.colorPalette.searchBarBackground
        viewQR.backgroundColor = Appearance.default.colorPalette.searchBarBackground
        qrCodeView.backgroundColor = Appearance.default.colorPalette.qrBackground
    }

    private func generateQRCode() {
        guard let strLinkUrl = dynamicLinkUrl?.absoluteString,
              let qrCode = EFQRCode.generate(for: strLinkUrl) else {
            return
        }
        imgQRCode.image = UIImage(cgImage: qrCode)
    }

    private func fetchDynamicLink() {
        guard let controller = channelController else {
            return
        }
        ChatClientConfiguration.shared.requestedGeneralGroupDynamicLink = { [weak self] url in
            guard let self = self else {
                return
            }
            self.indicator.isHidden = true
            guard let linkUrl = url else {
                return
            }
            self.btnShare.isEnabled = true
            self.dynamicLinkUrl = linkUrl
            self.generateQRCode()
        }
        let parameter = [kInviteGroupID: controller.channel?.cid.description]
        NotificationCenter.default.post(name: .generalGroupInviteLink, object: nil, userInfo: parameter)
    }

    // MARK: - IB Actions
    @IBAction func btnShareAction(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let `self` = self else { return }
            let uiimage = self.viewPreview.asImage(rect: self.viewPreview.bounds)
            var userInfo = [String: Any]()
            userInfo["image"] = uiimage
            userInfo["groupName"] = self.channelController?.channel?.name
            NotificationCenter.default.post(name: .showActivityAction, object: nil, userInfo: userInfo)
        }
    }
}

