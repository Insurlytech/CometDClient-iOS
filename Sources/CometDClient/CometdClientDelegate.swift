//
//  CometdClientDelegate.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

public enum SubscriptionError: Error {
  case error(subscription: String, error: String)
}

// MARK: CometdClientDelegate
public protocol CometdClientDelegate: class {
  func messageReceived(messageDict: NSDictionary, channel: String)
  func pongReceived()
  func connectedToServer()
  func handshakeSucceeded(handshakeDict: NSDictionary)
  func handshakeFailed()
  func disconnectedFromServer()
  func disconnectedAdviceReconnect()
  func connectionFailed()
  func didSubscribeToChannel(channel: String)
  func didUnsubscribeFromChannel(channel: String)
  func subscriptionFailedWithError(error: SubscriptionError)
  func cometdClientError(error: Error)
}

public extension CometdClientDelegate {
  func messageReceived(messageDict: NSDictionary, channel: String) { }
  func pongReceived() { }
  func connectedToServer() { }
  func handshakeSucceeded(handshakeDict: NSDictionary) { }
  func handshakeFailed() { }
  func disconnectedFromServer() { }
  func disconnectedAdviceReconnect() { }
  func connectionFailed() { }
  func didSubscribeToChannel(channel: String) { }
  func didUnsubscribeFromChannel(channel: String) { }
  func subscriptionFailedWithError(error: SubscriptionError) { }
  func cometdClientError(error: Error) { }
}
