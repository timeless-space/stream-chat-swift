//
//  PrivateGroupOTPVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import CoreLocation
import StreamChat

open class PrivateGroupOTPVC: UIViewController {

    // MARK: - Variables
    var isPushed = false

    // MARK: - Outlets
    @IBOutlet private weak var viewSafeAreaHeader: UIView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var viewOTP: DPOTPView!
    @IBOutlet weak var lblOtpDetails: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var heightSafeAreaView: NSLayoutConstraint!
    
    // MARK: - view life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindClosure()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationPermission()
    }

    // MARK: - IBAction
    @IBAction func btnBackAction(_ sender: UIButton) {
        NotificationCenter.default.post(name: .showTabbar, object: nil)
        popWithAnimation()
    }

    // MARK: - Functions
    private func setupUI() {
        heightSafeAreaView.constant = UIView.safeAreaTop
        NotificationCenter.default.post(name: .hideTabbar, object: nil)
        viewOTP.dpOTPViewDelegate = self
        viewOTP.textColorTextField = .white
        viewSafeAreaHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        viewHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        btnBack.setTitle("", for: .normal)
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        LocationManager.shared.location.bind { [weak self] location in
            guard let self = self else {
                return
            }
            if !LocationManager.shared.isEmptyCurrentLoc() {
                if self.viewOTP.validate() {
                    self.pushToJoinPrivateGroup()
                }
            }
        }
        lblOtpDetails.text = "Join a group with friends nearby by \n entering the secret four digits"
    }

    private func bindClosure() {
        ChatClientConfiguration.shared.getPrivateGroup = { [weak self] groupInfo in
            guard let `self` = self, let info = groupInfo else { return }
            guard let joinPrivateGroupVC: JoinPrivateGroupVC = JoinPrivateGroupVC.instantiateController(storyboard: .PrivateGroup),
                  let opt = self.viewOTP.text,
                  !self.isPushed else {
                return
            }
            joinPrivateGroupVC.userStatus = (info.isMember ? .alreadyJoined : .joinGroup)
            joinPrivateGroupVC.passWord = opt
            joinPrivateGroupVC.groupInfo = info
            self.indicator.stopAnimating()
            self.isPushed = true
            self.pushWithAnimation(controller: joinPrivateGroupVC)
        }
        ChatClientConfiguration.shared.createPrivateGroup = { [weak self] groupInfo in
            guard let `self` = self else { return }
            guard let joinPrivateGroupVC: JoinPrivateGroupVC = JoinPrivateGroupVC.instantiateController(storyboard: .PrivateGroup),
                  let opt = self.viewOTP.text,
                  !self.isPushed else {
                return
            }
            joinPrivateGroupVC.userStatus = .createGroup
            joinPrivateGroupVC.passWord = opt
            joinPrivateGroupVC.createChannelInfo = groupInfo
            self.indicator.stopAnimating()
            self.isPushed = true
            self.pushWithAnimation(controller: joinPrivateGroupVC)
        }
    }

    private func checkLocationPermission() {
        if LocationManager.shared.hasLocationPermissionDenied() {
            LocationManager.showLocationPermissionAlert()
            viewOTP.resignFirstResponder()
        } else {
            LocationManager.shared.requestLocationAuthorization()
            LocationManager.shared.requestGPS()
            viewOTP.becomeFirstResponder()
        }
    }

    // MARK: - Navigations
    private func pushToJoinPrivateGroup() {
        guard viewOTP.validate() else { return }
        let parameter: [String: Any] = [kPrivateGroupLat: Float(LocationManager.shared.location.value.coordinate.latitude),
                         kPrivateGroupLon: Float(LocationManager.shared.location.value.coordinate.longitude),
                         kPrivateGroupPasscode: viewOTP.text ?? ""]
        NotificationCenter.default.post(name: .getPrivateGroup, object: nil, userInfo: parameter)
    }

    private func handleLocationPermissionAndPush() {
        viewOTP.resignFirstResponder()
        indicator.startAnimating()
        if LocationManager.shared.hasLocationPermissionDenied() {
            LocationManager.showLocationPermissionAlert()
        } else if !LocationManager.shared.isEmptyCurrentLoc() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.pushToJoinPrivateGroup()
            }
        }
    }
}

// MARK: - OTPView delegate
extension PrivateGroupOTPVC: DPOTPViewDelegate {
    public func dpOTPViewAddText(_ text: String, at position: Int) {
        if viewOTP.validate() {
            handleLocationPermissionAndPush()
        }
    }

    public func dpOTPViewRemoveText(_ text: String, at position: Int) {
        if viewOTP.validate() {
            handleLocationPermissionAndPush()
        }
    }

    public func dpOTPViewChangePositionAt(_ position: Int) {
    }

    public func dpOTPViewBecomeFirstResponder() {
    }

    public func dpOTPViewResignFirstResponder() {
    }
}
