//
//  CometdClient+Parsing.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftyJSON

extension CometdClient {
  // MARK: Parsing
  func parseCometdMessage(_ messages: [JSON]) {
    messages.forEach { (message) in
      guard let channel = message[Bayeux.Channel.rawValue].string else {
        log.warning("Cometd: Missing channel for \(message)")
        return
      }
      log.verbose("parseCometdMessage \(channel)")
      log.verbose(message)
      
      // Handle Meta Channels
      if let metaChannel = BayeuxChannel(rawValue: channel) {
        parseMetaChannel(metaChannel, for: message)
      } else {
        // Handle Client Channel
        guard isSubscribedToChannel(channel) else {
          log.warning("Cometd: Weird channel that not been set to subscribed: \(channel)")
          return
        }
        guard let data = message[Bayeux.Data.rawValue].object as? NSDictionary else {
          log.warning("Cometd: For some reason data is nil for channel: \(channel)")
          return
        }
        
        if let channelBlock = channelSubscriptionBlocks[channel] {
          for channel in channelBlock {
            channel.callback?(data)
          }
        } else {
          log.warning("Cometd: Failed to get channel block for : \(channel)")
        }
        delegate?.messageReceived(self, messageDict: data, channel: channel)
      }
    }
  }
  
  private func parseMetaChannel(_ metaChannel: BayeuxChannel, for message: JSON) {
    switch(metaChannel) {
    case .Handshake:
      cometdClientId = message[Bayeux.ClientId.rawValue].stringValue
      if message[Bayeux.Successful.rawValue].int == 1 {
        if let ext = message[Bayeux.Ext.rawValue].object as? NSDictionary {
          delegate?.handshakeSucceeded(self, handshakeDict: ext)
        }
        cometdConnected = true
        connect()
        subscribeQueuedSubscriptions()
      } else {
        delegate?.handshakeFailed(self)
        cometdConnected = false
        transport?.closeConnection()
        delegate?.disconnectedFromServer(self)
      }
    case .Connect:
      let advice = message[Bayeux.Advice.rawValue]
      let successful = message[Bayeux.Successful.rawValue]
      let reconnect = advice[BayeuxAdvice.Reconnect.rawValue].stringValue
      if successful.boolValue {
        if reconnect == BayeuxAdviceReconnect.Retry.rawValue {
          cometdConnected = true
          delegate?.connectedToServer(self)
          connect()
        } else {
          cometdConnected = false
        }
      } else {
        cometdConnected = false
        transport?.closeConnection()
        delegate?.disconnectedFromServer(self)
        if reconnect == BayeuxAdviceReconnect.Handshake.rawValue {
          delegate?.disconnectedAdviceReconnect(self)
        }
      }
    case .Disconnect:
      if message[Bayeux.Successful.rawValue].boolValue {
        cometdConnected = false
        transport?.closeConnection()
        delegate?.disconnectedFromServer(self)
      } else {
        cometdConnected = false
        transport?.closeConnection()
        delegate?.disconnectedFromServer(self)
      }
    case .Subscribe:
      if let success = message[Bayeux.Successful.rawValue].int, success == 1 {
        if let subscription = message[Bayeux.Subscription.rawValue].string {
          removeChannelFromPendingSubscriptions(subscription)
          
          openSubscriptions.append(CometdSubscriptionModel(subscriptionUrl: subscription, clientId: cometdClientId))
          delegate?.didSubscribeToChannel(self, channel: subscription)
        } else {
          log.warning("Cometd: Missing subscription for Subscribe")
        }
      } else if let error = message[Bayeux.Error.rawValue].string,
        let subscription = message[Bayeux.Subscription.rawValue].string { // Subscribe Failed
        removeChannelFromPendingSubscriptions(subscription)
        delegate?.subscriptionFailedWithError(self, error: SubscriptionError.error(subscription: subscription, error: error))
      }
    case .Unsubscibe:
      if let subscription = message[Bayeux.Subscription.rawValue].string {
        removeChannelFromOpenSubscriptions(subscription)
        delegate?.didUnsubscribeFromChannel(self, channel: subscription)
      } else {
        log.warning("Cometd: Missing subscription for Unsubscribe")
      }
    }
  }
}

