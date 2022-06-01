//
//  EmojiPickerViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/03/22.
//

import UIKit
import StreamChat
import Combine
import Nuke

@available(iOS 13.0, *)
class EmojiPickerViewController: UIViewController {

    public enum ScreenType: Int {
        case Animated, Sticker, MySticker
    }

    // MARK: Outlets
    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet weak var tblPicker: UITableView!

    // MARK: Variables
    private var stickerCalls = Set<AnyCancellable>()
    private var packages = [PackageList]()
    private var myStickers = [PackageList]()
    private var hiddenStickers = [PackageList]()
    private var pageMap: [String: Int]?
    private var isMyPackage = false
    var downloadedPackage = [Int]()
    var chatChannelController: ChatChannelController?
    private var dispatchGroup = DispatchGroup()

    override func viewDidLoad() {
        super.viewDidLoad()
        packages.removeAll()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
        fetchStickers(pageNumber: 0, animated: true)
        segmentController.selectedSegmentTintColor = Appearance.default.colorPalette.themeBlue
    }

    private func fetchStickers(pageNumber: Int, animated: Bool) {
        StickerApiClient.trendingStickers(pageNumber: pageNumber, animated: animated) { [weak self] result in
            guard let `self` = self else { return }
            let packages = result.body?.packageList ?? []
            self.packages.append(contentsOf: packages)
            self.packages.removeAll(where: { $0.price != "free" })
            self.packages.removeAll(where: { StickerMenu.getDefaultStickerIds().contains($0.packageID ?? 0 )})
            self.pageMap = result.body?.pageMap
            self.tblPicker.reloadData()
        }
    }

    private func fetchMySticker() {
        dispatchGroup.enter()
        StickerApiClient.mySticker { [weak self] result in
            guard let `self` = self else { return }
            self.myStickers.removeAll()
            self.myStickers = result.body?.packageList ?? []
            self.dispatchGroup.leave()
        }
    }

    private func getHiddenSticker() {
        dispatchGroup.enter()
        StickerApiClient.getHiddenStickers { [weak self] result in
            guard let `self` = self else { return }
            self.hiddenStickers.removeAll()
            self.hiddenStickers = result.body?.packageList ?? []
            for (index, _) in self.hiddenStickers.enumerated() {
                self.hiddenStickers[index].isHidden = true
            }
            self.dispatchGroup.leave()
        }
    }

    private func hidePackage(indexPath: IndexPath) {
        StickerApiClient.hideStickers(packageId: self.packages[indexPath.row].packageID ?? 0) { [weak self] _ in
            guard let `self` = self else { return }
            self.packages[indexPath.row].isHidden.toggle()
            self.tblPicker.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func getCurrentUserAllStickers() {
        fetchMySticker()
        getHiddenSticker()
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let `self` = self else { return }
            self.packages = self.myStickers + self.hiddenStickers
            self.packages.removeAll(where: { StickerMenu.getDefaultStickerIds().contains($0.packageID ?? 0 )})
            self.tblPicker.reloadData()
        }
    }

    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        packages.removeAll()
        tblPicker.reloadData()
        if sender.selectedSegmentIndex == 2 {
            isMyPackage = true
            getCurrentUserAllStickers()
        } else {
            isMyPackage = false
            fetchStickers(pageNumber: 0, animated: sender.selectedSegmentIndex == 0)
        }
    }

}

@available(iOS 13.0, *)
extension EmojiPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PickerTableViewCell") as? PickerTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.configure(with: packages[indexPath.row], downloadedPackage: downloadedPackage, screenType: segmentController.selectedSegmentIndex, indexPath: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        if let sendEmojiVc: SendEmojiViewController = SendEmojiViewController.instantiateController(storyboard: .wallet) {
            sendEmojiVc.packageInfo = packages[indexPath.row]
            sendEmojiVc.chatChannelController = chatChannelController
            present(sendEmojiVc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        isMyPackage
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(
            style: .destructive,
            title: self.packages[indexPath.row].isHidden ? "Unhide" : "Hide"
        ) { (action, sourceView, completionHandler) in
            self.hidePackage(indexPath: indexPath)
            completionHandler(true)
        }
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
}

@available(iOS 13.0, *)
extension EmojiPickerViewController: DownloadStickerDelegate {

    func onClickOfDownload(indexPath: IndexPath) {
        guard let packageId = packages[indexPath.row].packageID else { return }
        if packages[indexPath.row].isDownload != "Y" {
            StickerApiClient.downloadStickers(packageId: packages[indexPath.row].packageID ?? 0) { [weak self] _ in
                guard let `self` = self else { return }
                self.packages[indexPath.row].isDownload = "Y"
                self.downloadedPackage.append(packageId)
                self.tblPicker.reloadRows(at: [indexPath], with: .automatic)
            }
        } else {
            Snackbar.show(text: "Sticker already downloaded!", messageType: StreamChatMessageType.StickerAlreadyDownloaded)
        }
    }
}
