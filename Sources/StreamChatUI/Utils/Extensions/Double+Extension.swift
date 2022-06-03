//
//  Double+Extension.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 23/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

extension Double {
    // Format and split currency
    public func formatAndSplitCurrency(
        minimumFractionDigits: Int = 2,
        maximumFractionDigits: Int = 2
    ) -> [String] {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        let truncateNumber = truncate(places: maximumFractionDigits)
        if let formattedBalance = formatter.string(from: truncateNumber as NSNumber) {
            return formattedBalance.components(separatedBy: Locale.current.decimalSeparator ?? "")
        }
        return []
    }

    public func formatNumber(
        minimumFractionDigits: Int = 4,
        maximumFractionDigits: Int = 4,
        removeLastZero: Bool = false
    ) -> (formattedString: String, strBeforeDecimal: String, strAfterDecimal: String) {
        let formattedString = self.formatAndSplitCurrency(
            minimumFractionDigits: removeLastZero ? 0 : minimumFractionDigits,
            maximumFractionDigits: maximumFractionDigits
        )
        let strBeforeDecimal = formattedString.first ?? "0"
        var strAfterDecimal = ""
        guard let decimalSeparator = Locale.current.decimalSeparator else {
            if formattedString.count > 1 {
                strAfterDecimal = ".\(formattedString.last ?? "")"
            } else {
                if !removeLastZero && minimumFractionDigits > 0 {
                    strAfterDecimal = "." + (0..<minimumFractionDigits).map { _ in "0" }.joined()
                }
            }
            return (strBeforeDecimal + strAfterDecimal, strBeforeDecimal, strAfterDecimal)
        }
        if formattedString.count > 1 {
            strAfterDecimal = "\(decimalSeparator)\(formattedString.last ?? "")"
        } else {
            if !removeLastZero && minimumFractionDigits > 0 {
                strAfterDecimal = decimalSeparator + (0..<minimumFractionDigits).map { _ in "0" }.joined()
            }
        }
        return (strBeforeDecimal + strAfterDecimal, strBeforeDecimal, strAfterDecimal)
    }

    func truncate(places: Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self) / pow(10.0, Double(places)))
    }
}
