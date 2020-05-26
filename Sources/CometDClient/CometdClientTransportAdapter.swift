//
//  CometdClientTransportAdapter.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import XCGLogger

// MARK: Transport Delegate
class CometdClientTransportAdapter: TransportDelegate {
  // MARK: Properties
  private let bayeuxClient: BayeuxClientContract
  private let subscriber: SubscriberContract
  private let log: XCGLogger
  
  weak var delegate: CometdClientDelegate?
  
  private lazy var messageResolver = CometdClientMessageResolver(
    bayeuxClient: bayeuxClient,
    subscriber: subscriber,
    log: log,
    delegate: delegate
  )
  
  // MARK: Lifecycle
  init(bayeuxClient: BayeuxClientContract, subscriber: SubscriberContract, log: XCGLogger, delegate: CometdClientDelegate?) {
    self.bayeuxClient = bayeuxClient
    self.subscriber = subscriber
    self.log = log
    self.delegate = delegate
  }
  
  // MARK: TransportDelegate
  public func didConnect() {
    bayeuxClient.connectionInitiated = false
    log.debug("CometdClient didConnect")
    bayeuxClient.handshake()
  }
  
  public func didDisconnect(_ error: Error?) {
    log.debug("CometdClient didDisconnect")
    bayeuxClient.connectionInitiated = false
    bayeuxClient.isConnected = false
    delegate?.disconnectedFromServer()
  }
  
  public func didFailConnection(_ error: Error?) {
    log.warning("CometdClient didFailConnection")
    bayeuxClient.connectionInitiated = false
    bayeuxClient.isConnected = false
    delegate?.connectionFailed()
  }
  
  public func didWriteError(_ error: Error?) {
    delegate?.cometdClientError(error: error ?? CometdSocketError.transportWrite)
  }
  
  public func didReceiveMessage(_ text: String) {
    messageResolver.resolve(text: text)
  }
  
  public func didReceivePong() {
    delegate?.pongReceived()
  }
}
