//
//  NumberUtils.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 26/04/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

class NumberUtils {
    public class func formatCurrency(_ number: Double?) -> String {
        if let number = number {
            if let formattedBalance = NumberFormatter
                .twoFractionDigitFormatter.string(from: number as NSNumber)
            {
                return formattedBalance
            }
        }
        return "0.00"
    }

    public class func formatONE(_ number: Double?) -> String {
        if let number = number {
            if let formattedBalance = NumberFormatter
                .oneFractionDigitFormatter.string(from: number as NSNumber)
            {
                return formattedBalance
            }
        }
        return "0.000"
    }

    public class func formatBalance(_ number: Double?) -> String {
        if let number = number {
            if let formattedBalance = NumberFormatter
                .currencyFractionDigitFormatter.string(from: number as NSNumber)
            {
                return formattedBalance
            }
        }
        return "0.0000"
    }
}
