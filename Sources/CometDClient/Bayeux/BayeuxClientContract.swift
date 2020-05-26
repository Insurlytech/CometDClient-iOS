//
//  BayeuxClientContract.swift
//  
//
//  Created by Anthony Guiguen on 26/05/2020.
//

import Foundation

protocol BayeuxClientContract: class {
  var transport: Transport? { get set }
  var clientId: String? { get set }
  var isConnected: Bool { get set }
  var connectionInitiated: Bool { get set }
  var handshakeFields: [String: Any]? { get set }
  
  func handshake()
  func sendPing(_ data: Data, completion: (() -> Void)?)
  func openConnection()
  func connect()
  func closeConnection()
  func disconnect()
  
  func subscribe(_ models: [CometdSubscriptionModel]) throws
  func subscribe(_ model: CometdSubscriptionModel) throws
  func unsubscribe(_ channel: String)
  func publish(_ data: [String: Any], channel: String)
}
