//
//  Publisher+Extensions.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//
import Combine

@available(iOS 13.0, *)
extension Publisher {
    public func decodeFromJson<Item>(_ type: Item.Type) -> Publishers.Decode<Self, Item, JSONDecoder> where Item: Decodable, Self.Output == JSONDecoder.Input {
        return decode(type: type, decoder: JSONDecoder())
    }
}
