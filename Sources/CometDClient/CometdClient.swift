//
//  CometdClient.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import Starscream
import XCGLogger

// MARK: - CometdSubscriptionState
public enum CometdSubscriptionState {
  case pending(CometdSubscriptionModel)
  case subscribed(CometdSubscriptionModel)
  case queued(CometdSubscriptionModel)
  case subscribingTo(CometdSubscriptionModel)
  case unknown(CometdSubscriptionModel?)
  
  public var isSubscribingTo: Bool {
    switch self {
    case .subscribingTo:
      return true
    default:
      return false
    }
  }
  
  public var model: CometdSubscriptionModel? {
    switch self {
    case .pending(let model),
         .subscribed(let model),
         .queued(let model),
         .subscribingTo(let model),
         .unknown(let model?):
      return model
    default:
      return nil
    }
  }
}

public typealias ChannelSubscriptionBlock = (NSDictionary) -> Void

// MARK: - Subscription
public struct Subscription: Equatable {
  public var callback: ChannelSubscriptionBlock?
  public var channel: String
  public var id: Int
  
  public init(callback: ChannelSubscriptionBlock?, channel: String, id: Int) {
    self.callback = callback
    self.channel = channel
    self.id = id
  }
  
  public static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
    return lhs.id == rhs.id && lhs.channel == rhs.channel
  }
}

// MARK: - CometdClient
open class CometdClient: TransportDelegate {
  // MARK: Properties
  open var handshakeFields: [String: Any]?
  open var cometdClientId: String?
  
  open weak var delegate: CometdClientDelegate?
  
  var transport: WebsocketTransport?
  
  open var cometdConnected: Bool?
  
  let log = XCGLogger(identifier: "cometdLogger", includeDefaultDestinations: true)
  
  var connectionInitiated: Bool?
  var messageNumber: UInt32 = 0
  
  var forceSecure = false
  
  var logLevel: XCGLogger.Level = .severe
  
  var queuedSubscriptions = [CometdSubscriptionModel]()
  var pendingSubscriptions = [CometdSubscriptionModel]()
  var openSubscriptions = [CometdSubscriptionModel]()
  
  var channelSubscriptionBlocks = [String: [Subscription]]()
  
  lazy var pendingSubscriptionSchedule: Timer = {
    return Timer.scheduledTimer(timeInterval: 45, target: self, selector: #selector(pendingSubscriptionsAction(_:)), userInfo: nil, repeats: true)
  }()
  
  /// Default in 10 seconds
  let timeOut: Int
  
  let readOperationQueue = DispatchQueue(label: "com.cometdclient.read", attributes: [])
  let writeOperationQueue = DispatchQueue(label: "com.cometdclient.write", attributes: DispatchQueue.Attributes.concurrent)
  
  // MARK: Lifecycle
  public init(timeoutAdvice: Int = 10000) {
    self.cometdConnected = false
    self.connectionInitiated = false
    self.timeOut = timeoutAdvice
  }
  
  deinit {
    pendingSubscriptionSchedule.invalidate()
  }
  
  // MARK: Methods
  open func setLogLevel(logLevel: XCGLogger.Level) {
    self.log.setup(level: logLevel)
    self.logLevel = logLevel
  }
  
  open func configure(url: String, backoffIncrement: Int = 1000, maxBackoff: Int = 60000, appendMessageTypeToURL: Bool = false) {
    // Check protocol (only websocket for now)
    let rawUrl = URL(string: url)
    guard let path = rawUrl?.path, let host = rawUrl?.host else {
      fatalError(#function + "path or host is nil")
    }
    let port = rawUrl?.port
    let scheme = forceSecure ? "wss://" : "ws://"
    
    let cometdURLString: String
    if let port = port {
      cometdURLString = scheme + host + ":" + String(port) + path
    } else {
      cometdURLString = scheme + host + path
    }
    
    self.cometdConnected = false
    
    self.transport = WebsocketTransport(url: cometdURLString, logLevel: self.logLevel)
    self.transport?.delegate = self
  }
  
  open func connectHandshake(_ handshakeFields: [String: Any]) {
    self.handshakeFields = handshakeFields
    log.debug("CometdClient handshake")
    
    if self.connectionInitiated != true {
      self.transport?.openConnection()
      self.connectionInitiated = true
    } else {
      log.debug("Cometd: Connection established")
    }
  }
  
  open func getCometdClientId() -> String {
    return self.cometdClientId ?? ""
  }
  
  open func isConnected() -> Bool {
    return self.cometdConnected ?? false
  }
  
  open func setForceSecure(_ isSecure: Bool) {
    self.forceSecure = isSecure
  }
  
  open func disconnectFromServer() {
    unsubscribeAllSubscriptions()
    self.disconnect()
  }
  
  open func sendMessage(_ messageDict: NSDictionary, channel: String) {
    guard let message = messageDict as? [String: Any] else {
      log.error("messageDict isn't castable into Dictionary")
      return
    }
    self.publish(message, channel: channel)
  }
  
  open func sendMessage(_ messageDict: [String: Any], channel: String) {
    self.publish(messageDict, channel: channel)
  }
  
  open func sendPing(_ data: Data, completion: (() -> Void)?) {
    writeOperationQueue.async { [weak self] in
      self?.transport?.sendPing(data, completion: completion)
    }
  }
  
  open func modelToSubscription(tuple: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let model = tuple.model
    var sub = Subscription(callback: nil, channel: model.subscriptionUrl, id: 0)
    if let block = tuple.block {
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
    } else if self.cometdConnected == false {
      // If connection is not yet established
      self.queuedSubscriptions.append(model)
      return (.queued(model), sub)
    } else {
      return (.subscribingTo(model), sub)
    }
  }
  
  open func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: cometdClientId)
    let tuple = ModelBlockTuple(model: model, block: block)
    return modelToSubscription(tuple: tuple)
  }
  
  open func subscribeToChannel(_ model: CometdSubscriptionModel, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    let tuple = ModelBlockTuple(model: model, block: block)
    return modelToSubscription(tuple: tuple)
  }
  
  open func unsubscribeFromChannel(_ subscription: Subscription) {
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
  
  open func clearSubscriptionFromChannel(_ subscription: Subscription) {
    removeChannelFromQueuedSubscriptions(subscription.channel)
    // Empty the multi-callback storage array
    self.channelSubscriptionBlocks[subscription.channel]?.removeAll()
    // Unsubscribe from the server
    self.unsubscribe(subscription.channel)
    
    self.channelSubscriptionBlocks[subscription.channel] = nil
    removeChannelFromOpenSubscriptions(subscription.channel)
    removeChannelFromPendingSubscriptions(subscription.channel)
  }
}
