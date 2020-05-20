//
//  CometdClient+Transport.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

// MARK: Transport Delegate
extension CometdClient {
  public func didConnect() {
    self.connectionInitiated = false
    log.debug("CometdClient didConnect")
    guard let handshakeFields = self.handshakeFields else {
      log.debug("handshakeFields is nil")
      return
    }
    self.handshake(handshakeFields)
  }
  
  public func didDisconnect(_ error: Error?) {
    log.debug("CometdClient didDisconnect")
    self.connectionInitiated = false
    self.cometdConnected = false
    self.delegate?.disconnectedFromServer(self)
  }
  
  public func didFailConnection(_ error: Error?) {
    log.warning("CometdClient didFailConnection")
    self.connectionInitiated = false
    self.cometdConnected = false
    self.delegate?.connectionFailed(self)
  }
  
  public func didWriteError(_ error: Error?) {
    self.delegate?.cometdClientError(self, error: error ?? CometdSocketError.transportWrite)
  }
  
  public func didReceiveMessage(_ text: String) {
    self.receive(text)
  }
  
  public func didReceivePong() {
    self.delegate?.pongReceived(self)
  }
}
