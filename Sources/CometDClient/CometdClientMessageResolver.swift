//
//  CometdClientMessageResolver.swift
//  
//
//  Created by Anthony Guiguen on 25/05/2020.
//

import Foundation
import SwiftyJSON
import XCGLogger

protocol CometdClientMessageResolverDelegate: class {
  func didReceiveMessage(dictionary: NSDictionary, from channel: String, resolver: CometdClientMessageResolver)
  func handshakeDidSucceeded(dictionary: NSDictionary, from resolver: CometdClientMessageResolver)
  func handshakeDidFailed(from resolver: CometdClientMessageResolver)
  func didDisconnected(from adapter: CometdClientMessageResolver)
  func didAdvisedToReconnect(from adapter: CometdClientMessageResolver)
  func didConnected(from adapter: CometdClientMessageResolver)
  func didSubscribeToChannel(channel: String, from resolver: CometdClientMessageResolver)
  func didUnsubscribeFromChannel(channel: String, from resolver: CometdClientMessageResolver)
  func subscriptionFailedWithError(error: SubscriptionError, from resolver: CometdClientMessageResolver)
}

class CometdClientMessageResolver {
  // MARK: Properties
  private let bayeuxClient: BayeuxClientContract
  private let subscriber: SubscriberContract
  private let log: XCGLogger
  private let readOperationQueue = DispatchQueue(label: "com.cometdclient.read", attributes: [])
  
  weak var delegate: CometdClientMessageResolverDelegate?
  
  // MARK: Lifecycle
  init(bayeuxClient: BayeuxClientContract, subscriber: SubscriberContract, log: XCGLogger, delegate: CometdClientMessageResolverDelegate?) {
    self.bayeuxClient = bayeuxClient
    self.subscriber = subscriber
    self.log = log
    self.delegate = delegate
  }
  
  // MARK: Resolve
  func resolve(text: String) {
    readOperationQueue.sync { [weak self] in
      guard let jsonData = text.data(using: String.Encoding.utf8, allowLossyConversion: false),
        let json = try? JSON(data: jsonData) else { return }
      self?.resolve(messages: json.arrayValue)
    }
  }
  
  private func resolve(messages: [JSON]) {
    messages.forEach { (message) in
      guard let channel = message[Bayeux.channel.rawValue].string else {
        log.warning("Cometd: Missing channel for \(message)")
        return
      }
      log.verbose("parseCometdMessage \(channel)")
      log.verbose(message)
      
      // Handle Meta Channels
      if let metaChannel = BayeuxChannel(rawValue: channel) {
        resolve(metaChannel: metaChannel, for: message)
      } else {
        // Handle Client Channel
        guard subscriber.isSubscribedToChannel(channel) else {
          log.warning("Cometd: Weird channel that not been set to subscribed: \(channel)")
          return
        }
        guard let data = message[Bayeux.data.rawValue].object as? NSDictionary else {
          log.warning("Cometd: For some reason data is nil for channel: \(channel)")
          return
        }
        
        if let channelBlock = subscriber.channelSubscriptionBlocks[channel] {
          for channel in channelBlock {
            channel.callback?(data)
          }
        } else {
          log.warning("Cometd: Failed to get channel block for : \(channel)")
        }
        delegate?.didReceiveMessage(dictionary: data, from: channel, resolver: self)
      }
    }
  }
  
  // MARK: Resolve META
  private func resolve(metaChannel: BayeuxChannel, for message: JSON) {
    switch(metaChannel) {
    case .handshake:
      resolveMetaHandshake(for: message)
    case .connect:
      resolveMetaConnect(for: message)
    case .disconnect:
      resolveMetaDisconnect(for: message)
    case .subscribe:
      resolveMetaSubscribe(for: message)
    case .unsubscibe:
      resolveMetaUnsubscibe(for: message)
    }
  }
  
  private func resolveMetaHandshake(for message: JSON) {
    bayeuxClient.clientId = message[Bayeux.clientId.rawValue].stringValue
    if message[Bayeux.successful.rawValue].int == 1 {
      if let ext = message[Bayeux.ext.rawValue].object as? NSDictionary {
        delegate?.handshakeDidSucceeded(dictionary: ext, from: self)
      }
      bayeuxClient.isConnected = true
      bayeuxClient.connect()
      subscriber.subscribeQueuedSubscriptions()
    } else {
      delegate?.handshakeDidFailed(from: self)
      bayeuxClient.isConnected = false
      
      bayeuxClient.closeConnection()
      delegate?.didDisconnected(from: self)
    }
  }
  
  private func resolveMetaConnect(for message: JSON) {
    let advice = message[Bayeux.advice.rawValue]
    let successful = message[Bayeux.successful.rawValue]
    let reconnect = advice[BayeuxAdvice.reconnect.rawValue].stringValue
    if successful.boolValue {
      if reconnect == BayeuxAdviceReconnect.retry.rawValue {
        bayeuxClient.isConnected = true
        delegate?.didConnected(from: self)
        bayeuxClient.connect()
      } else {
        bayeuxClient.isConnected = false
      }
    } else {
      bayeuxClient.isConnected = false
      bayeuxClient.closeConnection()
      delegate?.didDisconnected(from: self)
      if reconnect == BayeuxAdviceReconnect.handshake.rawValue {
        delegate?.didAdvisedToReconnect(from: self)
      }
    }
  }
  
  private func resolveMetaDisconnect(for message: JSON) {
    if message[Bayeux.successful.rawValue].boolValue {
      bayeuxClient.isConnected = false
      bayeuxClient.closeConnection()
      delegate?.didDisconnected(from: self)
    } else {
      bayeuxClient.isConnected = false
      bayeuxClient.closeConnection()
      delegate?.didDisconnected(from: self)
    }
  }
  
  private func resolveMetaSubscribe(for message: JSON) {
    if let success = message[Bayeux.successful.rawValue].int, success == 1 {
      if let subscription = message[Bayeux.subscription.rawValue].string {
        subscriber.removeChannelFromPendingSubscriptions(subscription)
        
        subscriber.openSubscriptions.append(CometdSubscriptionModel(subscriptionUrl: subscription, clientId: bayeuxClient.clientId))
        delegate?.didSubscribeToChannel(channel: subscription, from: self)
      } else {
        log.warning("Cometd: Missing subscription for Subscribe")
      }
    } else if let error = message[Bayeux.error.rawValue].string,
      let subscription = message[Bayeux.subscription.rawValue].string { // Subscribe Failed
      subscriber.removeChannelFromPendingSubscriptions(subscription)
      delegate?.subscriptionFailedWithError(error: SubscriptionError.error(subscription: subscription, error: error), from: self)
    }
  }
  
  private func resolveMetaUnsubscibe(for message: JSON) {
    if let subscription = message[Bayeux.subscription.rawValue].string {
      subscriber.removeChannelFromOpenSubscriptions(subscription)
      delegate?.didUnsubscribeFromChannel(channel: subscription, from: self)
    } else {
      log.warning("Cometd: Missing subscription for Unsubscribe")
    }
  }
}
