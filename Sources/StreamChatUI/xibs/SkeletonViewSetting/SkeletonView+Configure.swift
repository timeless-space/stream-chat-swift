//
//  SkeletonView+Configure.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 15/04/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SkeletonView

public extension SkeletonAppearance {

    public struct Settings {
        public static let shimmerBackgroundColor = Appearance.default.colorPalette.placeHolderBalanceBG
        public static var shimmerGradient: SkeletonGradient = {
            return SkeletonGradient(colors: [
                shimmerBackgroundColor.withAlphaComponent(0.5),
                shimmerBackgroundColor.withAlphaComponent(0.2),
                shimmerBackgroundColor.withAlphaComponent(0.5)])
        }()

        public static func setShimmerEffect() {
            SkeletonAppearance.default.gradient = SkeletonAppearance.Settings.shimmerGradient
        }
    }
}
