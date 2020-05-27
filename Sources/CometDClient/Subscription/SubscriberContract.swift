//
//  SubscriberContract.swift
//  
//
//  Created by Anthony Guiguen on 26/05/2020.
//

import Foundation

protocol SubscriberContract: class {
  var openSubscriptions: [CometdSubscriptionModel] { get set }
  var channelSubscriptionBlocks: [String: [Subscription]] { get set }
  
  func subscribe(_ models: [CometdSubscriptionModel])
  func subscribe(_ model: CometdSubscriptionModel)
  func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock?) -> (state: CometdSubscriptionState, subscription: Subscription?)
  func unsubscribe(_ channel: String)
  func unsubscribeFromChannel(_ subscription: Subscription)
  func unsubscribeAllSubscriptions()
  func subscribeQueuedSubscriptions()
  @discardableResult
  func removeChannelFromPendingSubscriptions(_ channel: String) -> Bool
  @discardableResult
  func removeChannelFromOpenSubscriptions(_ channel: String) -> Bool
  func transformModelBlockToSubscription(modelBlock: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?)
  func isSubscribedToChannel(_ channel: String) -> Bool
}
