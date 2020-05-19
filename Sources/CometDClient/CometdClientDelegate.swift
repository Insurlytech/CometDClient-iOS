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
  func messageReceived(_ client: CometdClient, messageDict: NSDictionary, channel: String)
  func pongReceived(_ client: CometdClient)
  func connectedToServer(_ client: CometdClient)
  func handshakeSucceeded(_ client: CometdClient, handshakeDict: NSDictionary)
  func handshakeFailed(_ client: CometdClient)
  func disconnectedFromServer(_ client: CometdClient)
  func disconnectedAdviceReconnect(_ client: CometdClient)
  func connectionFailed(_ client: CometdClient)
  func didSubscribeToChannel(_ client: CometdClient, channel: String)
  func didUnsubscribeFromChannel(_ client: CometdClient, channel: String)
  func subscriptionFailedWithError(_ client: CometdClient, error: SubscriptionError)
  func cometdClientError(_ client: CometdClient, error: Error)
}

public extension CometdClientDelegate {
  func messageReceived(_ client: CometdClient, messageDict: NSDictionary, channel: String) { }
  func pongReceived(_ client: CometdClient) { }
  func connectedToServer(_ client: CometdClient) { }
  func handshakeSucceeded(_ client: CometdClient, handshakeDict: NSDictionary) { }
  func handshakeFailed(_ client: CometdClient) { }
  func disconnectedFromServer(_ client: CometdClient) { }
  func disconnectedAdviceReconnect(_ client: CometdClient) { }
  func connectionFailed(_ client: CometdClient) { }
  func didSubscribeToChannel(_ client: CometdClient, channel: String) { }
  func didUnsubscribeFromChannel(_ client: CometdClient, channel: String) { }
  func subscriptionFailedWithError(_ client: CometdClient, error: SubscriptionError) { }
  func cometdClientError(_ client: CometdClient, error: Error) { }
}
