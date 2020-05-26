//
//  BayeuxClient.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation
import SwiftyJSON
import XCGLogger

class BayeuxClient: BayeuxClientContract {
  // MARK: Properties
  private let writeOperationQueue = DispatchQueue(label: "com.cometdclient.write", attributes: .concurrent)
  private let log: XCGLogger
  private let timeOut: Int
  private var messageNumber: UInt32 = 0
  
  var transport: Transport?
  var clientId: String?
  var isConnected = false
  var connectionInitiated = false
  var handshakeFields: [String: Any]?
  
  // MARK: Lifecycle
  init(log: XCGLogger, timeOut: Int) {
    self.log = log
    self.timeOut = timeOut
  }
  
  // MARK: Connection

  // Bayeux Handshake
  // "channel": "/meta/handshake",
  // "version": "1.0",
  // "minimumVersion": "1.0beta",
  // "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
  func handshake() {
    guard let data = self.handshakeFields else {
      log.debug("handshakeFields is nil")
      return
    }
    writeOperationQueue.sync { [weak self] in
      let connTypes = [BayeuxConnection.longPolling.rawValue, BayeuxConnection.callback.rawValue, BayeuxConnection.iFrame.rawValue, BayeuxConnection.webSocket.rawValue]
      
      var dict: [String: Any] = [
        Bayeux.channel.rawValue: BayeuxChannel.handshake.rawValue,
        Bayeux.version.rawValue: "1.0",
        Bayeux.minimumVersion.rawValue: "1.0",
        Bayeux.supportedConnectionTypes.rawValue: connTypes,
      ]
      
      let ext: [String: Any] = [
        "authentication": data
      ]
      let advice: [String: Any] = [
        "interval": 0,
        "timeout": 6000
      ]
      
      dict["ext"] = ext
      dict["advice"] = advice
      
      if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
        self?.log.verbose("CometdClient handshake \(string)")
        self?.transport?.writeString("["+string+"]")
      }
    }
  }
  
  func sendPing(_ data: Data, completion: (() -> Void)?) {
    writeOperationQueue.async { [weak self] in
      self?.transport?.sendPing(data, completion: completion)
    }
  }
  
  func openConnection() {
    transport?.openConnection()
  }
  
  // Bayeux Connect
  // "channel": "/meta/connect",
  // "clientId": "Un1q31d3nt1f13r",
  // "connectionType": "long-polling"
  func connect() {
    writeOperationQueue.sync { [weak self] in
      guard let self = self, let clientId = self.clientId else { return }
      let messageId = self.nextMessageId()
      let dict: [String: Any] = [
        Bayeux.id.rawValue: messageId,
        Bayeux.channel.rawValue: BayeuxChannel.connect.rawValue,
        Bayeux.clientId.rawValue: clientId,
        Bayeux.connectionType.rawValue: BayeuxConnection.webSocket.rawValue,
        Bayeux.advice.rawValue: ["timeout": self.timeOut]
      ]
      
      if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient connect \(string)")
        self.transport?.writeString("["+string+"]")
      }
    }
  }
  
  func closeConnection() {
    transport?.closeConnection()
  }
  
  // Bayeux Disconnect
  // "channel": "/meta/disconnect",
  // "clientId": "Un1q31d3nt1f13r"
  func disconnect() {
    guard let clientId = clientId, isConnected else { return }
    writeOperationQueue.sync { [weak self] in
      guard let self = self else { return }
      let messageId = self.nextMessageId()
      let dict: [String: Any] = [
        Bayeux.id.rawValue: messageId,
        Bayeux.channel.rawValue: BayeuxChannel.disconnect.rawValue,
        Bayeux.clientId.rawValue: clientId
      ]
      if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient disconnect \(string)")
        self.transport?.writeString("["+string+"]")
      }
    }
  }
  
  // Bayeux Subscribe
  func subscribe(_ models: [CometdSubscriptionModel]) throws {
    try writeOperationQueue.sync { [weak self] in
      guard let self = self, let clientId = self.clientId else {
        throw CometdSubscriptionModelError.clientIdNotValid
      }
      let dictionaries = models.compactMap({
        [
          Bayeux.channel.rawValue: $0.bayeuxChannel.rawValue,
          Bayeux.clientId.rawValue: clientId,
          Bayeux.id.rawValue: $0.id,
          Bayeux.subscription.rawValue: $0.subscriptionUrl
        ]
      })
      
      if let string = JSON(dictionaries).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient subscribe \(string)")
        self.transport?.writeString(string)
      } else {
        throw CometdSubscriptionModelError.conversationError
      }
    }
  }
  
  // MARK: Subscription
  
  // Bayeux Subscribe
  // "channel": "/meta/subscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  func subscribe(_ model: CometdSubscriptionModel) throws {
    try writeOperationQueue.sync { [weak self] in
      guard let self = self, let clientId = self.clientId else {
        throw CometdSubscriptionModelError.clientIdNotValid
      }
      let dictionary: [String: Any] = [
        Bayeux.channel.rawValue: model.bayeuxChannel.rawValue,
        Bayeux.clientId.rawValue: clientId,
        Bayeux.id.rawValue: model.id,
        Bayeux.subscription.rawValue: model.subscriptionUrl
      ]
      
      if let string = JSON(dictionary).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient subscribe \(string)")
        self.transport?.writeString("["+string+"]")
      } else {
        throw CometdSubscriptionModelError.conversationError
      }
    }
  }
  
  // Bayeux Unsubscribe
  // {
  // "channel": "/meta/unsubscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  // }
  func unsubscribe(_ channel: String) {
    writeOperationQueue.sync { [weak self] in
      guard let self = self, let clientId = self.clientId else { return }
      let dict: [String: Any] = [
        Bayeux.channel.rawValue: BayeuxChannel.unsubscibe.rawValue,
        Bayeux.clientId.rawValue: clientId,
        Bayeux.subscription.rawValue: channel
      ]
      
      if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient unsubscribe \(string)")
        self.transport?.writeString("["+string+"]")
      }
    }
  }
  
  // MARK: Publishing
  
  // Bayeux Publish
  // {
  // "channel": "/some/channel",
  // "clientId": "Un1q31d3nt1f13r",
  // "data": "some application string or JSON encoded object",
  // "id": "some unique message id"
  // }
  func publish(_ data: [String: Any], channel: String) {
    writeOperationQueue.sync { [weak self] in
      guard let self = self, let clientId = self.clientId, isConnected else { return }
      let messageId = self.nextMessageId()
      let dict: [String: Any] = [
        Bayeux.channel.rawValue: channel,
        Bayeux.clientId.rawValue: clientId,
        Bayeux.id.rawValue: messageId,
        Bayeux.data.rawValue: data
      ]
      
      if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
        self.log.verbose("CometdClient Publish \(string)")
        self.transport?.writeString("["+string+"]")
      }
    }
  }
  
  // MARK: Helper
  private func nextMessageId() -> String {
    self.messageNumber += 1
    
    if self.messageNumber >= UInt32.max {
      messageNumber = 0
    }
    
    // UTF 8 str from original
    // NSData! type returned (optional)
    guard let utf8str = "\(self.messageNumber)".data(using: String.Encoding.utf8) else {
      return ""
    }
    
    // Base64 encode UTF 8 string
    // fromRaw(0) is equivalent to objc 'base64EncodedStringWithOptions:0'
    // Notice the unwrapping given the NSData! optional
    // NSString! returned (optional)
    let base64Encoded = utf8str.base64EncodedString(options: NSData.Base64EncodingOptions())
    
    // Base64 Decode (go back the other way)
    // Notice the unwrapping given the NSString! optional
    // NSData returned
    guard let data = Data(base64Encoded: base64Encoded, options: NSData.Base64DecodingOptions()),
      let base64Decoded = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
        return ""
    }
    return base64Decoded as String
  }
}
