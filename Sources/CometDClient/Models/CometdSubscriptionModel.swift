//
//  CometdSubscriptionModel.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftyJSON

public enum CometdSubscriptionModelError: Error {
  case conversationError
  case clientIdNotValid
}

// MARK: CometdSubscriptionModel
///  Subscription Model
open class CometdSubscriptionModel {
  static var id = 0
  /// Subscription URL
  public let subscriptionUrl: String
  
  /// Channel type for request
  public let bayeuxChannel: BayeuxChannel
  
  /// Uniqle client id for socket
  open var clientId: String?
  
  // Id of the subscribtion
  open var id: Int
  
  /// Model must conform to Hashable
  open var hashValue: Int {
    return subscriptionUrl.hashValue
  }
  
  // MARK: Lifecycle
  public init(subscriptionUrl: String, bayeuxChannel: BayeuxChannel = .subscribe, clientId: String?) {
    self.subscriptionUrl = subscriptionUrl
    self.bayeuxChannel = bayeuxChannel
    self.clientId = clientId
    CometdSubscriptionModel.id += 1
    self.id = CometdSubscriptionModel.id
  }
}

// MARK: Description
extension CometdSubscriptionModel: CustomStringConvertible {
  public var description: String {
    let dict: [String : Any] = [
      Bayeux.channel.rawValue: bayeuxChannel.rawValue,
      Bayeux.clientId.rawValue: clientId ?? "clientId instance is nil",
      Bayeux.id.rawValue: id,
      Bayeux.subscription.rawValue: subscriptionUrl
    ]
    return "CometdSubscriptionModel: \(String(describing: dict))"
  }
}

// MARK: Equatable
public func ==(lhs: CometdSubscriptionModel, rhs: CometdSubscriptionModel) -> Bool {
  return lhs.hashValue == rhs.hashValue
}
