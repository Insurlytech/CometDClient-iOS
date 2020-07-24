//
//  CometdClientContract.swift
//  
//
//  Created by Anthony Guiguen on 26/05/2020.
//

import Foundation
import XCGLogger

public protocol CometdClientContract: class {
  var isConnected: Bool { get }
  var clientId: String? { get }
  var log: XCGLogger { get }
  var delegate: CometdClientDelegate? { get set }
  var recorder: CometDClientRecorder? { get }
  
  func configure(url: String, backoffIncrement: Int, maxBackoff: Int, appendMessageTypeToURL: Bool, recorder: CometDClientRecorder?)
  
  func handshake(fields: [String: Any])
  func disconnectFromServer()
  func setForceSecure(_ isSecure: Bool)
  
  func subscribe(_ models: [CometdSubscriptionModel])
  func subscribe(_ model: CometdSubscriptionModel)
  func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock?) -> (state: CometdSubscriptionState, subscription: Subscription?)
  func unsubscribeFromChannel(_ subscription: Subscription)
  func transformModelBlockToSubscription(modelBlock: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?)
  
  func publish(_ data: [String: Any], channel: String)
}

public extension CometdClientContract {
  func configure(url: String, recorder: CometDClientRecorder?) {
    configure(url: url, backoffIncrement: 1000, maxBackoff: 60000, appendMessageTypeToURL: false, recorder: recorder)
  }
}
