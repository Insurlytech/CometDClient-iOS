//
//  Subscriber.swift
//  
//
//  Created by Anthony Guiguen on 25/05/2020.
//

import Foundation
import SwiftyJSON
import XCGLogger

class Subscriber: SubscriberContract {
  // MARK: Properties
  // Avoid Data Races : Unsynchronized access to mutable state across multiple threads
  private let queuedSubscriptionsQueue = DispatchQueue(label: "com.cometdclient.queuedSubscriptions.queue", attributes: .concurrent)
  private var _queuedSubscriptions = [CometdSubscriptionModel]()
  private var queuedSubscriptions: [CometdSubscriptionModel] {
    get { queuedSubscriptionsQueue.sync { self._queuedSubscriptions } }
    set {
      queuedSubscriptionsQueue.async(flags: .barrier) { [weak self] in
        self?._queuedSubscriptions = newValue
      }
    }
  }
  // Avoid Data Races : Unsynchronized access to mutable state across multiple threads
  private let pendingSubscriptionsQueue = DispatchQueue(label: "com.cometdclient.pendingSubscriptions.queue", attributes: .concurrent)
  private var _pendingSubscriptions = [CometdSubscriptionModel]()
  private var pendingSubscriptions: [CometdSubscriptionModel] {
    get { pendingSubscriptionsQueue.sync { self._pendingSubscriptions } }
    set {
      pendingSubscriptionsQueue.async(flags: .barrier) { [weak self] in
        self?._pendingSubscriptions = newValue
      }
    }
  }
  private var bayeuxClient: BayeuxClientContract
  private let log: XCGLogger
  
  // Avoid Data Races : Unsynchronized access to mutable state across multiple threads
  private let openSubscriptionsQueue = DispatchQueue(label: "com.cometdclient.openSubscriptions.queue", attributes: .concurrent)
  private var _openSubscriptions = [CometdSubscriptionModel]()
  var openSubscriptions: [CometdSubscriptionModel] {
    get { openSubscriptionsQueue.sync { self._openSubscriptions } }
    set {
      openSubscriptionsQueue.async(flags: .barrier) { [weak self] in
        self?._openSubscriptions = newValue
      }
    }
  }
  var channelSubscriptionBlocks = [String: [Subscription]]()
  
  private lazy var pendingSubscriptionSchedule = Timer.scheduledTimer(
    timeInterval: 45,
    target: self,
    selector: #selector(pendingSubscriptionsAction(_:)),
    userInfo: nil,
    repeats: true
  )
  
  // MARK: Lifecycle
  init(bayeuxClient: BayeuxClientContract, log: XCGLogger) {
    self.bayeuxClient = bayeuxClient
    self.log = log
  }
  
  deinit {
    pendingSubscriptionSchedule.invalidate()
  }
  
  // MARK: Methods
  func subscribe(_ models: [CometdSubscriptionModel]) {
    do {
      try bayeuxClient.subscribe(models)
      pendingSubscriptions.append(contentsOf: models)
    } catch CometdSubscriptionModelError.clientIdNotValid where (bayeuxClient.clientId?.count ?? 0) > 0 {
        models.forEach({ $0.clientId = bayeuxClient.clientId })
        self.subscribe(models)
    } catch { }
  }
  
  // Bayeux Subscribe
  // "channel": "/meta/subscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  func subscribe(_ model: CometdSubscriptionModel) {
    do {
      try bayeuxClient.subscribe(model)
      pendingSubscriptions.append(model)
    } catch CometdSubscriptionModelError.clientIdNotValid where (bayeuxClient.clientId?.count ?? 0) > 0 {
        let model = model
        model.clientId = self.bayeuxClient.clientId
        self.subscribe(model)
    } catch { }
  }
  
  // Bayeux Unsubscribe
  // {
  // "channel": "/meta/unsubscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  // }
  func unsubscribe(_ channel: String) {
    bayeuxClient.unsubscribe(channel)
  }
  
  func subscribeQueuedSubscriptions() {
    // if there are any outstanding open subscriptions resubscribe
    self.queuedSubscriptions.forEach { removeChannelFromQueuedSubscriptions($0.subscriptionUrl) }
    self.subscribe(self.queuedSubscriptions)
  }
  
  func resubscribeToPendingSubscriptions() {
    if !pendingSubscriptions.isEmpty {
      log.debug("Cometd: Resubscribing to \(pendingSubscriptions.count) pending subscriptions")
      self.pendingSubscriptions.forEach { removeChannelFromPendingSubscriptions($0.subscriptionUrl) }
      self.subscribe(self.pendingSubscriptions)
    }
  }
  
  func transformModelBlockToSubscription(modelBlock: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let model = modelBlock.model
    var sub = Subscription(callback: nil, channel: model.subscriptionUrl, id: 0)
    if let block = modelBlock.block {
      if self.channelSubscriptionBlocks[model.subscriptionUrl] == nil {
        self.channelSubscriptionBlocks[model.subscriptionUrl] = []
      }
      sub.callback = block
      sub.id = self.channelSubscriptionBlocks[model.subscriptionUrl]?.count ?? 0
      
      self.channelSubscriptionBlocks[model.subscriptionUrl]?.append(sub)
    }
    
    if self.isSubscribedToChannel(model.subscriptionUrl) {
      // If channel is already subscribed
      log.info("CometdClient subscribeToChannel intial subscription")
      return (.subscribed(model), sub)
    } else if self.pendingSubscriptions.contains(where: { $0 == model }) {
      // If channel is already in pending status
      log.info("CometdClient subscribeToChannel pending subscription")
      return (.pending(model), sub)
    } else if !bayeuxClient.isConnected {
      // If connection is not yet established
      self.queuedSubscriptions.append(model)
      return (.queued(model), sub)
    } else {
      return (.subscribingTo(model), sub)
    }
  }
  
  func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: bayeuxClient.clientId)
    let tuple = ModelBlockTuple(model: model, block: block)
    return transformModelBlockToSubscription(modelBlock: tuple)
  }
  
  func subscribeToChannel(_ model: CometdSubscriptionModel, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let tuple = ModelBlockTuple(model: model, block: block)
    return transformModelBlockToSubscription(modelBlock: tuple)
  }
  
  func unsubscribeFromChannel(_ subscription: Subscription) {
    removeChannelFromQueuedSubscriptions(subscription.channel)
    
    var subscriptionArray = self.channelSubscriptionBlocks[subscription.channel]
    if let index = subscriptionArray?.firstIndex(of: subscription) {
      subscriptionArray?.remove(at: index)
    }
    if subscriptionArray?.count == 0 {
      self.unsubscribe(subscription.channel)
      
      self.channelSubscriptionBlocks[subscription.channel] = nil
      removeChannelFromOpenSubscriptions(subscription.channel)
      removeChannelFromPendingSubscriptions(subscription.channel)
    }
  }
  
  func unsubscribeAllSubscriptions() {
    let subscriptionsModels = queuedSubscriptions + openSubscriptions + pendingSubscriptions
    let subscriptions = subscriptionsModels.compactMap({ Subscription(callback: nil, channel: $0.subscriptionUrl, id: $0.id) })
    subscriptions.forEach({ clearSubscriptionFromChannel($0) })
  }
  
  func clearSubscriptionFromChannel(_ subscription: Subscription) {
    removeChannelFromQueuedSubscriptions(subscription.channel)
    // Empty the multi-callback storage array
    self.channelSubscriptionBlocks[subscription.channel]?.removeAll()
    // Unsubscribe from the server
    self.unsubscribe(subscription.channel)
    
    self.channelSubscriptionBlocks[subscription.channel] = nil
    removeChannelFromOpenSubscriptions(subscription.channel)
    removeChannelFromPendingSubscriptions(subscription.channel)
  }
  
  @discardableResult
  func removeChannelFromQueuedSubscriptions(_ channel: String) -> Bool {
    let index = self.queuedSubscriptions.firstIndex { $0.subscriptionUrl == channel }
    
    if let index = index {
      self.queuedSubscriptions.remove(at: index)
      return true
    }
    return false
  }
  
  @discardableResult
  func removeChannelFromPendingSubscriptions(_ channel: String) -> Bool {
    let index = self.pendingSubscriptions.firstIndex { $0.subscriptionUrl == channel }
    
    if let index = index {
      self.pendingSubscriptions.remove(at: index)
      return true
    }
    return false
  }
  
  @discardableResult
  func removeChannelFromOpenSubscriptions(_ channel: String) -> Bool {
    let index = self.openSubscriptions.firstIndex { $0.subscriptionUrl == channel }
    
    if let index = index {
      self.openSubscriptions.remove(at: index)
      return true
    }
    return false
  }
  
  // MARK: Action
  @objc
  private func pendingSubscriptionsAction(_ timer: Timer) {
    guard bayeuxClient.isConnected else {
      log.error("Cometd: Failed to resubscribe to all pending channels, socket disconnected")
      return
    }
    resubscribeToPendingSubscriptions()
  }
  
  // MARK: Helper
  ///  Validate whatever a subscription has been subscribed correctly
  func isSubscribedToChannel(_ channel: String) -> Bool {
    return self.openSubscriptions.contains { $0.subscriptionUrl == channel }
  }
}
