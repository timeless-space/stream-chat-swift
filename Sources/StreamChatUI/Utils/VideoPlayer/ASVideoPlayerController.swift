//
//  ASAutoPlayVideoLayerContainer.swift
//  Timeless-wallet
//
//  Created by Parth Kshatriya on 19/11/21.
//
//

import UIKit
import AVFoundation

/**
 Protocol that needs to be adopted by subclass of any UIView
 that wants to play video.
 */
public protocol ASAutoPlayVideoLayerContainer {
    var videoURL: String? { get set }
    var imageUrl: String? { get set }
    var videoLayer: AVPlayerLayer { get set }
    var isVideoPlaying: Bool { get set }
}

open class ASVideoPlayerController: NSObject, NSCacheDelegate {
    var minimumLayerHeightToPlay: CGFloat = 60
    // Mute unmute video
    var mute = true
    var preferredPeakBitRate: Double = 1_000_000
    static var playerViewControllerKVOContext = 0
    static public let sharedVideoPlayer = ASVideoPlayerController()
    //video url for currently playing video
    private var videoURL: String?
    var currentCell: ASVideoTableViewCell?
    /**
     Stores video url as key and true as value when player item associated to the url
     is being observed for its status change.
     Helps in removing observers for player items that are not being played.
     */
    private var observingURLs = [String: Bool]()
    // Cache of player and player item
    private var videoCache = NSCache<NSString, ASVideoContainer>()
    private var videoLayers = VideoLayers()
    private var currentLayer: AVPlayerLayer?

    override init() {
        super.init()
        videoCache.delegate = self
    }

    /**
     Download of an asset of url if corresponding videocontainer
     is not present.
     Uses the asset to create new playeritem.
     */
    func setupVideoFor(url: String) {
        if self.videoCache.object(forKey: url as NSString) != nil {
            return
        }
        guard let URL = URL(string: url) else {
            return
        }
        let asset = AVURLAsset(url: URL)
        let requestedKeys = ["playable"]
        asset.loadValuesAsynchronously(forKeys: requestedKeys) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            /**
             Need to check whether asset loaded successfully, if not successful then don't create
             AVPlayer and AVPlayerItem and return without caching the videocontainer,
             so that, the assets can be tried to be downloaded again when need be.
             */
            var error: NSError?
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            switch status {
            case .loaded:
                break
            case .failed:
                debugPrint("Failed to load asset", URL)
                return
            case .cancelled:
                debugPrint("Cancelled to load asset")
            default:
                debugPrint("Unknown state of asset")
                return
            }
            let player = AVPlayer()
            let item = AVPlayerItem(asset: asset)
            DispatchQueue.main.async {
                let videoContainer = ASVideoContainer(player: player, item: item, url: url)
                strongSelf.videoCache.setObject(videoContainer, forKey: url as NSString)
                videoContainer.player.replaceCurrentItem(with: videoContainer.playerItem)
                /**
                 Try to play video again in case when playvideo method was called and
                 asset was not obtained, so, earlier video must have not run
                 */
                if strongSelf.videoURL == url, let layer = strongSelf.currentLayer {
                    strongSelf.playVideo(withLayer: layer, url: url)
                }
            }
        }
    }
    // Play video with the AVPlayerLayer provided
    func playVideo(withLayer layer: AVPlayerLayer, url: String) {
        videoURL = url
        currentLayer = layer
        if self.videoCache.object(forKey: url as NSString) == nil {
            setupVideoFor(url: url)
        }
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            layer.player = videoContainer.player
            videoContainer.playOn = true
            addObservers(url: url, videoContainer: videoContainer)
        }
        // Give chance for current video player to be ready to play
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if let videoContainer = self.videoCache.object(forKey: url as NSString),
               videoContainer.player.currentItem?.status == .readyToPlay {
                videoContainer.playOn = true
            }
        }
    }

    private func pauseVideo(forLayer layer: AVPlayerLayer, url: String) {
        layer.player?.seek(to: CMTime.zero)
        currentLayer?.player?.seek(to: CMTime.zero)
        videoURL = nil
        currentLayer = nil
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            videoContainer.playOn = false
            removeObserverFor(url: url)
        }
    }

    open func removeLayerFor(cell: ASAutoPlayVideoLayerContainer) {
        if let url = cell.videoURL {
            removeFromSuperLayer(layer: cell.videoLayer, url: url)
        }
    }

    private func removeFromSuperLayer(layer: AVPlayerLayer, url: String) {
        videoURL = nil
        currentLayer = nil
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            videoContainer.playOn = false
            removeObserverFor(url: url)
        }
        layer.player = nil
    }

    private func pauseRemoveLayer(layer: AVPlayerLayer, url: String, layerHeight: CGFloat) {
        pauseVideo(forLayer: layer, url: url)
    }

    // Play video again in case the current player has finished playing
    @objc func playerDidFinishPlaying(note: NSNotification) {
        guard let playerItem = note.object as? AVPlayerItem,
              let currentPlayer = currentVideoContainer()?.player else {
                  return
              }
        if let currentItem = currentPlayer.currentItem, currentItem == playerItem {
            currentPlayer.seek(to: CMTime.zero)
            currentPlayer.play()
        }
    }

    private func currentVideoContainer() -> ASVideoContainer? {
        if let currentVideoUrl = videoURL {
            if let videoContainer = videoCache.object(forKey: currentVideoUrl as NSString) {
                return videoContainer
            }
        }
        return nil
    }

    func currentVideoCell() -> ASVideoTableViewCell? {
        currentCell
    }

    private func addObservers(url: String, videoContainer: ASVideoContainer) {
        if self.observingURLs[url] == false || self.observingURLs[url] == nil {
            videoContainer.player.currentItem?.addObserver(self,
                                                           forKeyPath: "status",
                                                           options: [.new, .initial],
                                                           context: &ASVideoPlayerController.playerViewControllerKVOContext)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.playerDidFinishPlaying(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: videoContainer.player.currentItem)
            self.observingURLs[url] = true
        }
    }

    private func removeObserverFor(url: String) {
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            if let currentItem = videoContainer.player.currentItem, observingURLs[url] == true {
                currentItem.removeObserver(self,
                                           forKeyPath: "status",
                                           context: &ASVideoPlayerController.playerViewControllerKVOContext)
                NotificationCenter.default.removeObserver(self,
                                                          name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                          object: currentItem)
                observingURLs[url] = false
            }
        }
    }

    /**
     Play UITableViewCell's videoplayer that has max visible video layer height
     when the scroll stops.
     */
    open func pausePlayVideosFor(tableView: UITableView, appEnteredFromBackground: Bool = false, isScrolled: Bool = false) {
        let visibleCells = tableView.visibleCells
        var videoCellContainer: ASAutoPlayVideoLayerContainer?
        var maxHeight: CGFloat = 0.0
        for cellView in visibleCells {
            guard var containerCell = cellView as? ASAutoPlayVideoLayerContainer else {
                continue
            }
            let height = cellView.bounds.height
            if visibleCells.count <= 2 {
                tableView.indexPathsForVisibleRows?.forEach({ index in
                    let cellRect = tableView.rectForRow(at: index)
                    let completelyVisible = tableView.bounds.contains(cellRect)
                    // First cell
                    let lastCellIndex = (tableView.numberOfRows(inSection: 0) - 1)
                    if ((Int(cellRect.maxY) - Int(tableView.contentSize.height)) < 5) && index.row == lastCellIndex {
                        maxHeight = height
                        videoCellContainer = visibleCells.last as? ASAutoPlayVideoLayerContainer
                    } else {
                        if cellView == tableView.cellForRow(at: index) && completelyVisible {
                            maxHeight = height
                            videoCellContainer = containerCell
                        }
                    }
                })
                if visibleCells.count == 1 {
                    maxHeight = height
                    videoCellContainer = containerCell
                }
            } else if cellView == visibleCells.middle {
                // last cell
                if tableView.contentOffset.y == 0 {
                    maxHeight = height
                    videoCellContainer = visibleCells.first as? ASAutoPlayVideoLayerContainer
                } else {
                    maxHeight = height
                    videoCellContainer = containerCell
                }
            }

            if let cell = containerCell as? ASVideoTableViewCell {
                cell.videoLayer.isHidden = !cell.isVideoPlaying
                currentCell = cell
                // Disable gif support for now
                //                cell.imgView.stopAnimatingGif()
            }
        }
        guard var videoCell = videoCellContainer else { return }
        if isScrolled && videoCell.videoURL != videoURL {
            videoCell.isVideoPlaying = false
        }
        if videoCell.isVideoPlaying && !appEnteredFromBackground {
            return
        } else {
            for cellView in visibleCells {
                guard var containerCell = cellView as? ASAutoPlayVideoLayerContainer else {
                    continue
                }
                containerCell.isVideoPlaying = false
                if let videoCellURL = containerCell.videoURL {
                    pauseRemoveLayer(layer: containerCell.videoLayer, url: videoCellURL, layerHeight: cellView.bounds.height)
                }
            }
        }

        let minCellLayerHeight = videoCell.videoLayer.bounds.size.height * 0.5
        /**
         Visible video layer height should be at least more than max of predefined minimum height and
         cell's videolayer's 50% height to play video.
         */
        let minimumVideoLayerVisibleHeight = max(minCellLayerHeight, minimumLayerHeightToPlay)
        if maxHeight > minimumVideoLayerVisibleHeight {
            if let videoCellURL = videoCell.videoURL {
                if appEnteredFromBackground {
                    setupVideoFor(url: videoCellURL)
                }
                playVideo(withLayer: videoCell.videoLayer, url: videoCellURL)
            }

            videoCell.isVideoPlaying = true
            if let cell = videoCell as? ASVideoTableViewCell {
                cell.videoLayer.isHidden = !cell.isVideoPlaying
                currentCell = cell
                // Disable gif support for now
                // cell.imgView.startAnimatingGif()
            }
        }
    }

    // Set observing urls false when objects are removed from cache
    public func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if let videoObject = obj as? ASVideoContainer {
            observingURLs[videoObject.url] = false
        }
    }

    // Play video only when current videourl's player is ready to play
    //swiftlint:disable block_based_kvo
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &ASVideoPlayerController.playerViewControllerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if keyPath == "status" {
            /**
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newStatus: AVPlayerItem.Status
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                if newStatus == .readyToPlay {
                    guard let item = object as? AVPlayerItem,
                          let currentItem = currentVideoContainer()?.player.currentItem else {
                              return
                          }
                    if item == currentItem && currentVideoContainer()?.playOn == true {
                        currentVideoContainer()?.playOn = true
                    }
                }
            } else {
                newStatus = .unknown
            }
        }
    }
}
