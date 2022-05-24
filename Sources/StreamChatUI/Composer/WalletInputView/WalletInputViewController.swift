//
//  WalletInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit
import StreamChat

class WalletInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var viewKeypad: UIStackView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet var btnKeyPad: [UIButton]!
    @IBOutlet weak var walletStepper: WalletStepper!
    @IBOutlet weak var btnDecimalSeparator: UIButton!

    // MARK: - Variables
    var updatedAmount = 0.0
    var paymentType: WalletAttachmentPayload.PaymentType = .request
    var didHide: ((Double, WalletAttachmentPayload.PaymentType) -> Void)?
    var didUpdateAmount: ((Double) -> Void)?
    var isInputViewLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        btnKeyPad.forEach { btn in
            btn.layer.cornerRadius = 30
        }
        btnClose.setImage(Appearance.default.images.closePopup, for: .normal)
        walletStepper.updateAmount(amount: updatedAmount)
        btnDecimalSeparator.setTitle(Constants.decimalSeparator, for: .normal)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didUpdateAmount?(walletStepper.value)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        paymentType = .request
        NotificationCenter.default.post(name: .hidePaymentOptions, object: nil, userInfo: ["isHide": false])
        self.dismiss(animated: true, completion: nil)
        didHide?(walletStepper.getAmount(), paymentType)
    }

    @IBAction func btnSendAction(_ sender: Any) {
        paymentType = .pay
        NotificationCenter.default.post(name: .hidePaymentOptions, object: nil, userInfo: ["isHide": false])
        self.dismiss(animated: true, completion: nil)
        didHide?(walletStepper.getAmount(), paymentType)
    }

    @IBAction func btnKeypadAction(_ sender: UIButton) {
        if !isInputViewLoad {
            if sender.titleLabel?.text == Constants.decimalSeparator {
                walletStepper.insertNumber(numberValue: sender.titleLabel?.text)
            } else if let amount = Double(sender.titleLabel?.text ?? "") {
                walletStepper.updateAmount(amount: amount)
            }
            isInputViewLoad = true
        } else {
            walletStepper.insertNumber(numberValue: sender.titleLabel?.text)
        }
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
