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
  private lazy var transportAdapter = CometdClientTransportAdapter(
    bayeuxClient: bayeuxClient,
    subscriber: subscriber,
    log: log,
    delegate: self,
    recorder: recorder
  )
  
  private var forceSecure = false
  /// Default in 10 seconds
  private let timeOut: Int
  
  public let log = XCGLogger(identifier: "cometdLogger", includeDefaultDestinations: true)
  public var isConnected: Bool { bayeuxClient.isConnected }
  public var clientId: String? { bayeuxClient.clientId }
  
  public private(set) weak var recorder: CometDClientRecorder?
  public weak var delegate: CometdClientDelegate?
    
  // MARK: Lifecycle
  public init(timeoutAdvice: Int = 10000) {
    self.timeOut = timeoutAdvice
  }
  
  // MARK: Configure
  public func setForceSecure(_ isSecure: Bool) {
    self.forceSecure = isSecure
  }
  
  public func configure(url: String, backoffIncrement: Int = 1000, maxBackoff: Int = 60000, appendMessageTypeToURL: Bool = false, recorder: CometDClientRecorder?) {
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
    
    self.recorder = recorder
    let transport = WebsocketTransport(url: cometdURLString, logLevel: log.outputLevel, recorder: recorder)
    transport.delegate = transportAdapter
    self.bayeuxClient.transport = transport
  }
  
  // MARK: Connection
  public func handshake(fields: [String: Any]) {
    bayeuxClient.openConnection(with: fields)
  }
  
  public func sendPing(_ data: Data, completion: (() -> Void)?) {
    bayeuxClient.sendPing(data, completion: completion)
  }
  
  public func disconnectFromServer() {
    subscriber.unsubscribeAllSubscriptions()
    bayeuxClient.disconnect()
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

extension CometdClient: CometdClientTransportAdapterDelegate {
  // MARK: CometdClientTransportAdapterDelegate
  func didReceivePong(from adapter: CometdClientTransportAdapter) {
    delegate?.didReceivePong(from: self)
  }
  func didWriteError(error: Error, from adapter: CometdClientTransportAdapter) {
    delegate?.didWriteError(error: CometDClientError.write, from: self)
  }
  func didLostConnection(error: Error, from adapter: CometdClientTransportAdapter) {
    delegate?.didLostConnection(error: CometDClientError.lostConnection, from: self)
  }
  func didDisconnected(error: Error, from adapter: CometdClientTransportAdapter) {
    delegate?.didDisconnected(error: CometDClientError.lostConnection, from: self)
  }
}

extension CometdClient: CometdClientMessageResolverDelegate {
  // MARK: CometdClientMessageResolverDelegate
  func didReceiveMessage(dictionary: NSDictionary, from channel: String, resolver: CometdClientMessageResolver) {
    delegate?.didReceiveMessage(dictionary: dictionary, from: channel, client: self)
  }
  func handshakeDidSucceeded(dictionary: NSDictionary, from resolver: CometdClientMessageResolver) {
    delegate?.handshakeDidSucceeded(dictionary: dictionary, from: self)
  }
  func handshakeDidFailed(error: Error, from resolver: CometdClientMessageResolver) {
    let handshakeError: CometDClientError
    switch error {
    case let error as CometdClientMessageResolverError where error.code == CometdClientMessageResolverError.Constant.SIMPLE_UNMATCHED_LOGIN_PASSWORD:
      handshakeError = .handshake(reason: HandshakeError.wrongCredential)
    default:
      handshakeError = .handshake(reason: nil)
    }
    delegate?.handshakeDidFailed(error: handshakeError, from: self)
  }
  func didDisconnected(from adapter: CometdClientMessageResolver) {
    delegate?.didDisconnected(error: nil, from: self)
  }
  func didAdvisedToReconnect(from adapter: CometdClientMessageResolver) {
    delegate?.didAdvisedToReconnect(from: self)
  }
  func didConnected(from adapter: CometdClientMessageResolver) {
    delegate?.didConnected(from: self)
  }
  func didSubscribeToChannel(channel: String, from resolver: CometdClientMessageResolver) {
    delegate?.didSubscribeToChannel(channel: channel, from: self)
  }
  func didUnsubscribeFromChannel(channel: String, from resolver: CometdClientMessageResolver) {
    delegate?.didUnsubscribeFromChannel(channel: channel, from: self)
  }
  func subscriptionFailedWithError(error: Error, from resolver: CometdClientMessageResolver) {
    delegate?.subscriptionFailedWithError(error: CometDClientError.subscription, from: self)
  }
}
