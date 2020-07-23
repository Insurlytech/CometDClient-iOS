//
//  WebsocketTransport.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import Starscream
import XCGLogger

// MARK: - WebsocketTransport
class WebsocketTransport: Transport {
  // MARK: Properties
  private var urlString: String
  private var webSocket: WebSocket?
  weak var delegate: TransportDelegate?
  private(set) var isConnected = false
  
  let log = XCGLogger(identifier: "websocketLogger", includeDefaultDestinations: true)
  
  // MARK: Init
  init(url: String, logLevel: XCGLogger.Level = .severe) {
    self.urlString = url
    log.setup(level: logLevel)
  }
  
  func openConnection() {
    self.closeConnection()
    
    guard let url = URL(string: urlString) else {
      fatalError("WebSocket url isn't conform")
    }
    self.webSocket = WebSocket(request: URLRequest(url: url))
    if let webSocket = self.webSocket {
      webSocket.delegate = self
      webSocket.connect()
      
      log.debug("Cometd: Opening connection with \(String(describing: self.urlString))")
    }
  }
  
  func closeConnection() {
    log.error("Cometd: close connection")
    if let webSocket = self.webSocket {
      webSocket.delegate = nil
      webSocket.disconnect()
      self.webSocket = nil
    }
  }
  
  func writeString(_ aString: String) {
    log.debug("Cometd: aString : \(aString)")
    self.webSocket?.write(string: aString)
  }
  
  func sendPing(_ data: Data, completion: (() -> Void)? = nil) {
    self.webSocket?.write(ping: data, completion: completion)
  }
}

// MARK: - WebsocketTransport + WebSocketPongDelegate
extension WebsocketTransport: WebSocketDelegate {
  func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected(let headers):
      log.debug("Websocket is connected: \(headers)")
      isConnected = true
      self.delegate?.didConnect()
    case .disconnected(let reason, let code):
      log.debug("Websocket is disconnected: \(reason) with code: \(code)")
      isConnected = false
      delegate?.didDisconnect(.disconnected(reason: reason, code: Int(code)))
    case .text(let string):
      log.debug("Websocket received text: \(string)")
      self.delegate?.didReceiveMessage(string)
    case .binary(let data):
      log.debug("Websocket received data: \(data.count)")
    case .ping(let value):
      log.debug("Websocket ping: \(String(describing: value))")
    case .pong(let value):
      log.debug("Websocket pong: \(String(describing: value))")
      self.delegate?.didReceivePong()
    case .viabilityChanged(let connectionIsViable):
      log.debug("Websocket viability changed: \(connectionIsViable)")
      if !connectionIsViable && connectionIsViable != isConnected {
        isConnected = false
        self.delegate?.didLostConnection(.noLongerViable)
      }
    case .reconnectSuggested(let value):
      log.debug("Websocket reconnect suggested: \(value)")
    case .cancelled:
      log.debug("Websocket cancelled")
      if isConnected {
        isConnected = false
        self.delegate?.didLostConnection(.cancelled)
      }
    case .error(let error):
      log.error("Websocket error: \(error?.localizedDescription ?? "")")
      self.delegate?.didWriteError(.write(error: error))
      if isConnected {
        isConnected = false
        self.delegate?.didLostConnection(.noLongerViable)
      }
    }
  }
}
