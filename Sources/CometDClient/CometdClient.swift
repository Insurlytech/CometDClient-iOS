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

public class CometdClient: CometdClientContract {
  // MARK: Properties
  private lazy var bayeuxClient: BayeuxClientContract = BayeuxClient(log: log, timeOut: timeOut)
  private lazy var subscriber: SubscriberContract = Subscriber(bayeuxClient: bayeuxClient, log: log)
  private lazy var transportAdapter = CometdClientTransportAdapter(bayeuxClient: bayeuxClient, subscriber: subscriber, log: log, delegate: delegate)
  
  private var forceSecure = false
  /// Default in 10 seconds
  private let timeOut: Int
  
  public let log = XCGLogger(identifier: "cometdLogger", includeDefaultDestinations: true)
  public var isConnected: Bool { bayeuxClient.isConnected }
  public var clientId: String? { bayeuxClient.clientId }
  
  public weak var delegate: CometdClientDelegate?
    
  // MARK: Lifecycle
  public init(timeoutAdvice: Int = 10000) {
    self.timeOut = timeoutAdvice
  }
  
  // MARK: Configure
  public func configure(url: String, backoffIncrement: Int = 1000, maxBackoff: Int = 60000, appendMessageTypeToURL: Bool = false) {
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
    
    let transport = WebsocketTransport(url: cometdURLString, logLevel: log.outputLevel)
    transport.delegate = transportAdapter
    self.bayeuxClient.transport = transport
  }
  
  // MARK: Connection
  public func handshake(fields: [String: Any]) {
    self.bayeuxClient.handshakeFields = fields
    log.debug("CometdClient handshake")
    
    if self.bayeuxClient.connectionInitiated != true {
      self.bayeuxClient.openConnection()
      self.bayeuxClient.connectionInitiated = true
    } else {
      log.debug("Cometd: Connection established")
    }
  }
  
  public func sendPing(_ data: Data, completion: (() -> Void)?) {
    self.bayeuxClient.sendPing(data, completion: completion)
  }
  
  public func disconnectFromServer() {
    self.subscriber.unsubscribeAllSubscriptions()
    self.bayeuxClient.disconnect()
  }
  
  public func setForceSecure(_ isSecure: Bool) {
    self.forceSecure = isSecure
  }
  
  // MARK: Subscription
  public func transformModelBlockToSubscription(modelBlock: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    subscriber.transformModelBlockToSubscription(modelBlock: modelBlock)
  }
  
  public func subscribe(_ models: [CometdSubscriptionModel]) {
    subscriber.subscribe(models)
  }
  
  public func subscribe(_ model: CometdSubscriptionModel) {
    subscriber.subscribe(model)
  }
  
  public func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock?) -> (state: CometdSubscriptionState, subscription: Subscription?) {
    subscriber.subscribeToChannel(channel, block: block)
  }
  
  public func unsubscribeFromChannel(_ subscription: Subscription) {
    subscriber.unsubscribeFromChannel(subscription)
  }
  
  // MARK: Publishing
  public func publish(_ data: [String: Any], channel: String) {
    bayeuxClient.publish(data, channel: channel)
  }
}
