//
//  StackedItemsView.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 20/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that provides a stacked of scrollable items by wrapping a UICollectionView with a `StackedItemsLayout`
public class StackedItemsView<ItemType: Equatable, CellType: UICollectionViewCell>: UIView, UICollectionViewDataSource, UICollectionViewDelegate  {

    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: StackedItemsLayout())

    public var collectionFlowLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.itemSize = .init(width: 200, height: 200)
        return layout
    }

    /// this will be called to configure each cell
    public var configureItemHandler: ConfigureItemHandler?
    public typealias ConfigureItemHandler = (ItemType, CellType) -> Void

    /// this will be called when an item is selected
    public var selectionHandler: SelectionHandler?
    public typealias SelectionHandler = (ItemType, Int) -> Void

    public var isExpand = false

    /// The items this view displays
    public var items = [ItemType]() {
        didSet {
            guard items != oldValue else { return }
            setupCollectionFlowLayout()
        }
    }

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

    /// the corner radius for each item
    public var cornerRadius = CGFloat(20) {
        didSet {
            guard cornerRadius != oldValue else { return }
            collectionView.reloadData()
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
        let contentOffset = CGPoint(x: -collectionView.adjustedContentInset.left + xOffset, y: -collectionView.adjustedContentInset.top)
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
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
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
            cell.layer.shadowPath = UIBezierPath(roundedRect:CGRect(origin: .zero, size:  stackedItemsLayout.itemSize), cornerRadius: cornerRadius).cgPath
        } else {
            cell.layer.shadowPath = nil
        }
        configureItemHandler?(items[indexPath.row], cell as! CellType)

        return cell
    }

    // MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isExpand {
            selectionHandler?(items[indexPath.row], indexPath.row)
        } else if indexPath.row == currentlyFocusedItemIndex {
            collectionView.deselectItem(at: indexPath, animated: true)
            if !isExpand {
                expandView(index: indexPath.row)
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
        collectionView.collectionViewLayout = StackedItemsLayout()
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
        collectionView.frame = CGRect(origin: .zero, size: bounds.size)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func setupCollectionFlowLayout() {
        if items.count == 1 {
            collectionView.collectionViewLayout = collectionFlowLayout
            collectionView.isScrollEnabled = false
        } else {
            collectionView.collectionViewLayout = stackedItemsLayout
            collectionView.isScrollEnabled = true
        }
        collectionView.reloadData()
        scrollToItem(at: 0, animated: false)
    }

    public func expandView(index: Int) {
        if !isExpand && items.count > 1 {
            isExpand = true
            let focusIndex = currentlyFocusedItemIndex
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 20
            layout.itemSize = .init(width: 200, height: 260)
            collectionView.setCollectionViewLayout(layout, animated: true)
            collectionView.isPagingEnabled = false
        }
    }
}
