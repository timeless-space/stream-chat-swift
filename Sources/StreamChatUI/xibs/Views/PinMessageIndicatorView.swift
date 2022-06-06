//
//  PinMessageIndicatorView.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 06/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class PinMessageIndicatorView: UIView {
    // MARK: - Variables
    open private(set) lazy var tableView: UITableView = {
        return UITableView()
    }()
    open private(set) var scrollView: UIScrollView?
    open private(set) var stackView: UIStackView?
    open private(set) var highlightedView: UIView?
    open private(set) var highlightedTopConstraint: NSLayoutConstraint?
    private var indicatorViewSize: CGSize = .zero
    open var numberOfItems: Int = 0 {
        didSet {
            if numberOfItems == 1 {
                indicatorViewSize = CGSize(width: 2, height: 50)
            } else if numberOfItems == 2 {
                indicatorViewSize = CGSize(width: 2, height: 22)
            } else if numberOfItems == 3 {
                indicatorViewSize = CGSize(width: 2, height: 13)
            } else {
                indicatorViewSize = CGSize(width: 2, height: 10)
            }
        }
    }

    // MARK: - UI
    open func setupUI() {
        setupHighlightedView()
        setupScrollViewView()
        setupStackView()
        layoutHighlightedView()
        layoutScrollView()
        layoutStackView()
        scrollView?.contentSize = stackView?.frame.size ?? .zero
    }

    private func setupHighlightedView() {
        highlightedView?.removeFromSuperview()
        highlightedView = nil
        highlightedView = UIView()
        highlightedView?.translatesAutoresizingMaskIntoConstraints = false
        highlightedView?.backgroundColor = Appearance
            .default
            .colorPalette
            .themeBlue
        addSubview(highlightedView!)
    }

    private func setupScrollViewView() {
        scrollView?.removeFromSuperview()
        scrollView = nil
        scrollView = UIScrollView()
        scrollView?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView!)
    }

    private func setupStackView() {
        stackView?.removeFromSuperview()
        stackView = nil
        stackView = UIStackView()
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.axis = .vertical
        stackView?.spacing = 3
        scrollView?.addSubview(stackView!)
    }

    private func layoutHighlightedView() {
        guard let highlightedView = highlightedView else { return }
        NSLayoutConstraint.activate([
            highlightedView.leadingAnchor
                .constraint(equalTo: leadingAnchor, constant: 0),
            highlightedView.widthAnchor.constraint(equalToConstant: indicatorViewSize.width),
            highlightedView.heightAnchor.constraint(equalToConstant: indicatorViewSize.height)
        ])
        highlightedTopConstraint = highlightedView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        highlightedTopConstraint?.isActive = true
    }

    private func layoutScrollView() {
        guard let scrollView = scrollView else { return }
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func layoutStackView() {
        guard let stackView = stackView,
        let scrollView = scrollView else { return }
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        ])
        for i in 1...numberOfItems {
            let indicatorView = UIView()
            indicatorView.backgroundColor = Appearance
                .default
                .colorPalette
                .themeBlue.withAlphaComponent(0.5)
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.widthAnchor.constraint(equalToConstant: indicatorViewSize.width),
                indicatorView.heightAnchor.constraint(equalToConstant: indicatorViewSize.height),
            ])
        }
    }

    // MARK: - Actions
    open func updateIndicatorFor(index: Int) {
        guard let lastView = stackView?.subviews[index] else {
            return
        }
        let frame = stackView?
            .convert(lastView.frame, to: scrollView) ?? .zero
        scrollView?.scrollRectToVisible(frame, animated: true)
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let weakSelf = self else { return }
            guard frame.origin.y < weakSelf.bounds.height else {
                return
            }
            weakSelf.highlightedTopConstraint?.constant = abs(frame.origin.y)
            weakSelf.layoutIfNeeded()
        }
    }
}
