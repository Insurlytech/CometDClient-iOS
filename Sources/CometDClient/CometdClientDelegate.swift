//
//  CometdClientDelegate.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

// MARK: CometdClientDelegate
public protocol CometdClientDelegate: class {
  func didReceiveMessage(dictionary: NSDictionary, from channel: String, client: CometdClientContract)
  func didReceivePong(from client: CometdClientContract)
  func didConnected(from client: CometdClientContract)
  func handshakeDidSucceeded(dictionary: NSDictionary, from client: CometdClientContract)
  func handshakeDidFailed(from client: CometdClientContract)
  func didDisconnected(error: Error?, from client: CometdClientContract)
  func didAdvisedToReconnect(from client: CometdClientContract)
  func didFailConnection(error: Error?, from client: CometdClientContract)
  func didSubscribeToChannel(channel: String, from client: CometdClientContract)
  func didUnsubscribeFromChannel(channel: String, from client: CometdClientContract)
  func subscriptionFailedWithError(error: SubscriptionError, from client: CometdClientContract)
  func didWriteError(error: Error, from client: CometdClientContract)
}

public extension CometdClientDelegate {
  func didReceiveMessage(dictionary: NSDictionary, from channel: String, client: CometdClientContract) { }
  func didReceivePong(from client: CometdClientContract) { }
  func didConnected(from client: CometdClientContract) { }
  func handshakeDidSucceeded(dictionary: NSDictionary, from client: CometdClientContract) { }
  func handshakeDidFailed(from client: CometdClientContract) { }
  func didDisconnected(error: Error?, from client: CometdClientContract) { }
  func didAdvisedToReconnect(from client: CometdClientContract) { }
  func didFailConnection(error: Error?, from client: CometdClientContract) { }
  func didSubscribeToChannel(channel: String, from client: CometdClientContract) { }
  func didUnsubscribeFromChannel(channel: String, from client: CometdClientContract) { }
  func subscriptionFailedWithError(error: SubscriptionError, from client: CometdClientContract) { }
  func didWriteError(error: Error, from client: CometdClientContract) { }
}
