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
    
    public class func formatCurrency(_ number: Double?,
        minimumFractionDigits: Int = Constant.currency.minimumFractionDigits,
        maximumFractionDigits: Int = Constant.currency.maximumFractionDigits
    ) -> String {
        if let number = number {
            let formatter = NumberUtils.getNumberFormatter(minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
            if let formattedBalance = formatter.string(from: number as NSNumber) {
                return formattedBalance
            }
            return "0.00"
        }
        return "0.00"
    }

    public class func formatONE(_ number: Double?,
        minimumFractionDigits: Int = Constant.coin.minimumFractionDigits,
        maximumFractionDigits: Int = Constant.coin.maximumFractionDigits
    ) -> String {
        if let number = number {
            if let formattedBalance = getNumberFormatter(
                minimumFractionDigits: minimumFractionDigits,
                maximumFractionDigits: maximumFractionDigits
            ).string(from: number as NSNumber)
            {
                return formattedBalance
            }
        }
        return "0.000"
    }

    private static func getNumberFormatter(
        minimumFractionDigits: Int = 4,
        maximumFractionDigits: Int = 4
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.roundingMode = .down
        return formatter
    }
}
