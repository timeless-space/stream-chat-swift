//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// `UICollectionViewCell` for video gallery item.
open class VideoAttachmentGalleryCell: GalleryCollectionViewCell {
    /// A cell reuse identifier.
    open class var reuseId: String { String(describing: self) }
    
    /// A player that handles the video content.
    public var player: AVPlayer {
        playerView.player
    }

    /// Image view to be used for zoom in/out animation.
    open private(set) lazy var animationPlaceholderImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    /// A view that displays currently playing video.
    open private(set) lazy var playerView: PlayerView = components
        .playerView.init()
        .withoutAutoresizingMaskConstraints

    private var gradientLayer = CAGradientLayer()
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        animationPlaceholderImageView.clipsToBounds = true
        animationPlaceholderImageView.contentMode = .scaleAspectFit
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        scrollView.addSubview(animationPlaceholderImageView)
        animationPlaceholderImageView.pin(anchors: [.height, .width], to: contentView)
        
        animationPlaceholderImageView.addSubview(playerView)
        playerView.pin(to: animationPlaceholderImageView)
        playerView.pin(anchors: [.height, .width], to: animationPlaceholderImageView)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying(note:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerView.player.currentItem)
        gradientLayer.frame = frame
    }
    
    override open func updateContent() {
        super.updateContent()
        
        let videoAttachment = content?.attachment(payloadType: VideoAttachmentPayload.self)
        
        let newAssetURL = videoAttachment?.videoURL
        let currentAssetURL = (player.currentItem?.asset as? AVURLAsset)?.url

        if newAssetURL != currentAssetURL {
            let playerItem = newAssetURL.map {
                AVPlayerItem(asset: components.videoLoader.videoAsset(at: $0))
            }
            player.replaceCurrentItem(with: playerItem)
            if let url = newAssetURL {
                components.videoLoader.loadPreviewForVideo(at: url) { [weak self] in
                    guard let `self` = self else { return }
                    switch $0 {
                    case let .success(preview):
                        self.animationPlaceholderImageView.image = preview
                        self.addGradientLayer(
                            topColor: preview.averageColor?.cgColor,
                            bottomColor: preview.averageColor?.withAlphaComponent(0.3).cgColor
                        )
                    case .failure:
                        self.animationPlaceholderImageView.image = nil
                    }
                }
            }
        }
    }

    // Play video again in case the current player has finished playing
    @objc func playerDidFinishPlaying(note: NSNotification) {
        guard let playerItem = note.object as? AVPlayerItem,
              let currentPlayer = playerView.player as? AVPlayer else {
                  return
              }
        if let currentItem = currentPlayer.currentItem, currentItem == playerItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentPlayer.seek(to: CMTime.zero)
                currentPlayer.play()
            }
        }
    }

    func addGradientLayer(topColor: CGColor?, bottomColor: CGColor?) {
        gradientLayer.removeFromSuperlayer()
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        animationPlaceholderImageView
    }
}
