//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

/// Publisher to read keyboard changes.
protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

/// Default implementation.
extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}

/// View modifier for hiding the keyboard on tap.
struct HideKeyboardOnTapGesture: ViewModifier {
    var shouldAdd: Bool
    var onTapped: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .gesture(shouldAdd ? TapGesture().onEnded { _ in
                resignFirstResponder()
                if let onTapped = onTapped {
                    onTapped()
                }
            } : nil)
    }
    
    /// Resigns first responder and hides the keyboard.
    func resignFirstResponder() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
