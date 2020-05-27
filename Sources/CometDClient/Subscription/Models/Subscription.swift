//
//  Subscription.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public typealias ChannelSubscriptionBlock = (NSDictionary) -> Void

public struct Subscription: Equatable {
  // MARK: Properties
  public var callback: ChannelSubscriptionBlock?
  public var channel: String
  public var id: Int
  
  // MARK: Lifecycle
  public init(callback: ChannelSubscriptionBlock?, channel: String, id: Int) {
    self.callback = callback
    self.channel = channel
    self.id = id
  }
  
  // MARK: Equatable
  public static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
    return lhs.id == rhs.id && lhs.channel == rhs.channel
  }
}
