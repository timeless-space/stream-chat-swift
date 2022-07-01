//
//  LocationManager.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

public class Dynamic<T> {
    
    // MARK: Typealias
    public typealias Listener = (T) -> Void
    
    // MARK: Vars & Lets
    public var listener: Listener?
    public var value: T {
        didSet {
            self.fire()
        }
    }
    
    // MARK: Initialization
    init(_ v: T) {
        value = v
    }
    
    // MARK: Public func
    public func bind(_ listener: Listener?) {
        self.listener = listener
    }
    
    public func bindAndFire(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
    
    internal func fire() {
        self.listener?(value)
    }
    
}
