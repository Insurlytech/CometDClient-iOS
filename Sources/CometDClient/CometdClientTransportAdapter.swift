//
//  CometdClientTransportAdapter.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import XCGLogger

protocol CometdClientTransportAdapterDelegate: class {
  func didReceivePong(from adapter: CometdClientTransportAdapter)
  func didWriteError(error: Error, from adapter: CometdClientTransportAdapter)
  func didLostConnection(error: Error, from adapter: CometdClientTransportAdapter)
  func didDisconnected(error: Error, from adapter: CometdClientTransportAdapter)
}

// MARK: Transport Delegate
class CometdClientTransportAdapter: TransportDelegate {
  typealias Delegate = (CometdClientTransportAdapterDelegate & CometdClientMessageResolverDelegate)
  
  // MARK: Properties
  private let bayeuxClient: BayeuxClientContract
  private let subscriber: SubscriberContract
  private let log: XCGLogger
  private weak var recorder: CometDClientRecorder?
  
  weak var delegate: Delegate?
  
  private lazy var messageResolver = CometdClientMessageResolver(
    bayeuxClient: bayeuxClient,
    subscriber: subscriber,
    log: log,
    delegate: delegate,
    recorder: recorder
  )
  
  // MARK: Lifecycle
  init(bayeuxClient: BayeuxClientContract, subscriber: SubscriberContract, log: XCGLogger, delegate: Delegate?, recorder: CometDClientRecorder?) {
    self.bayeuxClient = bayeuxClient
    self.subscriber = subscriber
    self.log = log
    self.delegate = delegate
    self.recorder = recorder
  }
  
  // MARK: TransportDelegate
  public func didConnect() {
    bayeuxClient.connectionInitiated = false
    log.debug("CometdClient didConnect")
    bayeuxClient.handshake()
  }
  
  
  func didDisconnect(_ error: Error) {
    log.debug("CometdClient didDisconnect")
    bayeuxClient.connectionInitiated = false
    bayeuxClient.isConnected = false
    delegate?.didDisconnected(error: error, from: self)
  }
  
  func didLostConnection(_ error: Error) {
    log.warning("CometdClient didFailConnection")
    bayeuxClient.connectionInitiated = false
    bayeuxClient.isConnected = false
    delegate?.didLostConnection(error: error, from: self)
  }
  
  func didWriteError(_ error: Error?) {
    delegate?.didWriteError(error: error ?? WebsocketTransportError.write(error: nil), from: self)
  }
  
  public func didReceiveMessage(_ text: String) {
    messageResolver.resolve(text: text)
  }
  
  public func didReceivePong() {
    delegate?.didReceivePong(from: self)
  }
}
