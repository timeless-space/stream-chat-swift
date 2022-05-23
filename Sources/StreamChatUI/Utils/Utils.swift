//
//  NumberUtils.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 26/04/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

class NumberUtils {
    struct Constant {
        enum currency {
            static let minimumFractionDigits = 2
            static let maximumFractionDigits = 2
        }

        enum coin {
            static let minimumFractionDigits = 4
            static let maximumFractionDigits = 4
        }
    }
    
    class func formatCurrency(
        _ number: Double,
        minimumFractionDigits: Int = Constant.currency.minimumFractionDigits,
        maximumFractionDigits: Int = Constant.currency.maximumFractionDigits,
        removeLastZero: Bool = false
    ) -> String {
        return number.formatNumber(
            minimumFractionDigits: minimumFractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            removeLastZero: removeLastZero
        ).formattedString
    }

    class func formatONE(
        _ number: Double,
        minimumFractionDigits: Int = Constant.coin.minimumFractionDigits,
        maximumFractionDigits: Int = Constant.coin.maximumFractionDigits,
        removeLastZero: Bool = false
    ) -> String {
        return number.formatNumber(
            minimumFractionDigits: minimumFractionDigits,
            maximumFractionDigits: maximumFractionDigits,
            removeLastZero: removeLastZero
        ).formattedString
    }
}
