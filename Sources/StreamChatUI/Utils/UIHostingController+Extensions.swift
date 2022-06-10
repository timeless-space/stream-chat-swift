//
//  UIHostingController+Extensions.swift
//  StreamChatUI
//
//  Created by Phu Tran on 11/05/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension UIHostingController {
    public convenience init(rootView: Content, ignoreSafeArea: Bool = false, ignoreKeyboardAvoidance: Bool = false) {
        self.init(rootView: rootView)
        registerCustomizeClass(with: ignoreSafeArea, ignoreKeyboardAvoidance: ignoreKeyboardAvoidance)
    }

    private func registerCustomizeClass(with ignoreSafeArea: Bool = false, ignoreKeyboardAvoidance: Bool = false) {
        guard let viewClass = object_getClass(view), (ignoreSafeArea == true || ignoreKeyboardAvoidance == true) else { return }

        var viewSubclassName = String(cString: class_getName(viewClass))
        if ignoreSafeArea { viewSubclassName.append("_IgnoreSafeArea") }
        if ignoreKeyboardAvoidance { viewSubclassName.append("_IgnoreKeyboardAvoidance") }

        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
        } else {
            guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
            guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }

            if ignoreSafeArea,
               let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
                let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                    return .zero
                }
                class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets),
                                imp_implementationWithBlock(safeAreaInsets),
                                method_getTypeEncoding(method))
            }

            if ignoreKeyboardAvoidance,
               let method = class_getInstanceMethod(viewClass, NSSelectorFromString("keyboardWillShowWithNotification:")) {
                let keyboardWillShow: @convention(block) (AnyObject, AnyObject) -> Void = { _, _ in }
                class_addMethod(viewSubclass, NSSelectorFromString("keyboardWillShowWithNotification:"),
                                imp_implementationWithBlock(keyboardWillShow), method_getTypeEncoding(method))
            }

            objc_registerClassPair(viewSubclass)
            object_setClass(view, viewSubclass)
        }
    }
}
