//
//  StackedItemsView.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 20/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that provides a stacked of scrollable items by wrapping a UICollectionView with a `StackedItemsLayout`
public class StackedItemsView<ItemType: Equatable, CellType: UICollectionViewCell>:
    UIView,
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: StackedItemsLayout())

    public var collectionFlowLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.itemSize = .init(width: 250, height: 200)
        return layout
    }

    /// this will be called to configure each cell
    public var configureItemHandler: ConfigureItemHandler?
    public var leftPadding = 0.0
    private var trailingConst: NSLayoutConstraint?
    private var leadingConst: NSLayoutConstraint?
    public typealias ConfigureItemHandler = (ItemType?, CellType) -> Void

    /// this will be called when an item is selected
    public var selectionHandler: SelectionHandler?
    public typealias SelectionHandler = (ItemType?, Int) -> Void
    private var btnExpand: CustomButton = {
        let expandBtn = CustomButton()
        expandBtn.setImage(Appearance.default.images.expandStack, for: .normal)
        expandBtn.translatesAutoresizingMaskIntoConstraints = false
        expandBtn.addTarget(self, action: #selector(expandView), for: .touchUpInside)
        return expandBtn
    }()

    public var isExpand: Bool {
        return !(collectionView.collectionViewLayout is StackedItemsLayout)
    }

    /// The items this view displays
    public var items = [ItemType]()

    /// the horizontal alignment of the stack inside this view
    public var horizontalAlignment: StackedItemsLayout.HorizontalAlignment {
        get { stackedItemsLayout.horizontalAlignment }
        set { stackedItemsLayout.horizontalAlignment = newValue }
    }

    /// the verticalAlignment alignment of the stack inside this view
    public var verticalAlignment: StackedItemsLayout.VerticalAlignment {
        get { stackedItemsLayout.verticalAlignment }
        set { stackedItemsLayout.verticalAlignment = newValue }
    }

    // the size of each item in the stack
    public var itemSize: CGSize {
        get {
            return stackedItemsLayout.itemSize
        }
        set {
            guard itemSize != newValue else { return }
            stackedItemsLayout.itemSize = newValue
            invalidateIntrinsicContentSize()
        }
    }

    /// the index of the item that is currently focused and on the top of the stack
    public var currentlyFocusedItemIndex: Int {
        return stackedItemsLayout.currentlyFocusedItemIndex
    }

    /// the pan gesture recognizer for the collection view
    public var panGestureRecognizer: UIPanGestureRecognizer {
        collectionView.panGestureRecognizer
    }

    /// scrolls to a specific item by making it top of the stack
    public func scrollToItem(at index: Int, animated: Bool) {
        let xOffset = collectionView.bounds.width * CGFloat(index)
        let contentOffset = CGPoint(
            x: -collectionView.adjustedContentInset.left + xOffset,
            y: -collectionView.adjustedContentInset.top
        )
        collectionView.setContentOffset(contentOffset, animated: animated)
        if animated == false {
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
        }
    }

    /// returns the cell at the given index, if visible
    public func cell(at index: Int) -> CellType? {
        return collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CellType
    }

    // MARK: UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isExpand ? (items.count + 1) : items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = UIColor.init(red: 0.074, green: 0.082, blue: 0.105, alpha: 1)
        if !isExpand {
            cell.contentView.clipsToBounds = true
            cell.contentView.layer.cornerRadius = cornerRadius
            cell.contentView.layer.allowsEdgeAntialiasing = true

            if #available(iOS 13, *) {
                cell.contentView.layer.cornerCurve = .continuous
            }
            cell.layer.allowsEdgeAntialiasing = true
            cell.layer.shadowRadius = 4
            cell.layer.shadowOpacity = 0.15
            cell.layer.shadowOffset = .zero
            cell.layer.shadowPath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size:  stackedItemsLayout.itemSize),
                cornerRadius: cornerRadius
            ).cgPath
        } else {
            cell.layer.shadowPath = nil
        }
        if indexPath.row >= items.count {
            configureItemHandler?(nil, cell as! CellType)
        } else {
            configureItemHandler?(items[indexPath.row], cell as! CellType)
        }

        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let previewCell = cell as? MediaPreviewCollectionCell {
            ASVideoPlayerController.sharedVideoPlayer.removeLayerFor(cell: previewCell)
        }
    }

    // MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isExpand || items.count == 1 {
            if indexPath.row >= items.count {
                selectionHandler?(nil, indexPath.row)
            } else {
                selectionHandler?(items[indexPath.row], indexPath.row)
            }
        } else if indexPath.row == currentlyFocusedItemIndex {
            collectionView.deselectItem(at: indexPath, animated: true)
            guard let cell = (collectionView.cellForItem(at: indexPath) as? MediaPreviewCollectionCell) else {
                return
            }
            if !isExpand {
                playSelectedIndex(index: -1)
                expandView()
            } else {
                selectionHandler?(items[indexPath.row], indexPath.row)
            }
        } else if indexPath.row < currentlyFocusedItemIndex {
            return scrollToItem(at: currentlyFocusedItemIndex - 1, animated: true)
        } else {
            return scrollToItem(at: currentlyFocusedItemIndex + 1, animated: true)
        }
    }

    // MARK: - Private
    private func setup() {
        collectionView.backgroundColor = nil
        collectionView.alwaysBounceHorizontal = true
        collectionView.clipsToBounds = false
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CellType.self, forCellWithReuseIdentifier: "Cell")
        addSubview(collectionView)
        addSubview(btnExpand)
        trailingConst = btnExpand.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30)
        leadingConst = btnExpand.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30)
        btnExpand.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        btnExpand.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btnExpand.widthAnchor.constraint(equalToConstant: 50).isActive = true
        setupStackedLayout()
    }

    private func setupStackedLayout() {
        let layout = StackedItemsLayout()
        layout.didChangeIndex = { [weak self] index in
            guard let `self` = self else { return }
            self.playSelectedIndex(index: index)
        }
        collectionView.collectionViewLayout = layout
    }

    private func playSelectedIndex(index: Int) {
        guard let cell = collectionView
                .cellForItem(at: .init(row: currentlyFocusedItemIndex, section: 0))
                as? MediaPreviewCollectionCell
        else {
            return
        }
        items.enumerated().forEach { index, _ in
            guard let previewCell = collectionView
                    .cellForItem(at: .init(row: index, section: 0))
                    as? MediaPreviewCollectionCell
            else {
                return
            }
            ASVideoPlayerController.sharedVideoPlayer.removeLayerFor(cell: previewCell)
        }
        guard index != -1 else { return }
        ASVideoPlayerController.sharedVideoPlayer.playSelectedCell(cell: cell)
    }

    private var stackedItemsLayout: StackedItemsLayout! {
        return collectionView.collectionViewLayout as? StackedItemsLayout ?? .init()
    }

    // MARK: - UIView
    public override var intrinsicContentSize: CGSize {
        return stackedItemsLayout.intrinsicContentSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        var size = bounds.size
        size.width += stackedItemsLayout.totalEffectiveHorizontalOffset
        if isExpand {
            collectionView.frame = CGRect(origin: .init(x: leftPadding, y: 0), size: bounds.size)
        } else {
            if self.horizontalAlignment == .leading {
                collectionView.frame = CGRect(origin:
                                                    .init(x: -(stackedItemsLayout.totalEffectiveHorizontalOffset - leftPadding),
                                                          y: 0),
                                              size: size)
            } else {
                collectionView.frame = CGRect(origin: .init(x: leftPadding, y: 0), size: bounds.size)
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func setupCollectionFlowLayout(_ isSender: Bool) {
        collectionView.isPagingEnabled = true
        collectionView.collectionViewLayout = stackedItemsLayout
        collectionView.clipsToBounds = true
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        scrollToItem(at: 0, animated: true)
        btnExpand.isHidden = isExpand
        leadingConst?.isActive = isSender
        trailingConst?.isActive = !isSender
        stackedItemsLayout.horizontalAlignment = !isSender ? .leading : .trailing
    }

    @objc private func expandView() {
        if !isExpand && items.count > 1 {
            let focusIndex = currentlyFocusedItemIndex
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 20
            layout.itemSize = .init(width: 200, height: 260)
            collectionView.setCollectionViewLayout(layout, animated: true)
            collectionView.isPagingEnabled = false
            btnExpand.isHidden = isExpand
            collectionView.reloadData()
            UIView.animate(withDuration: 0.5) {
                self.layoutSubviews()
                self.collectionView.scrollToItem(at: .init(row: 0, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    }
}
