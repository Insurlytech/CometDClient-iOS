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
  public init(subscriptionUrl: String, bayeuxChannel: BayeuxChannel = BayeuxChannel.Subscribe, clientId: String?) {
    self.subscriptionUrl = subscriptionUrl
    self.bayeuxChannel = bayeuxChannel
    self.clientId = clientId
    CometdSubscriptionModel.id += 1
    self.id = CometdSubscriptionModel.id
  }
  
  // MARK: JSON
  ///  Return Json string from model
  open func jsonString() throws -> String {
    do {
      guard let model = try JSON(toDictionary()).rawString() else {
        throw CometdSubscriptionModelError.conversationError
      }
      return model
    } catch {
      throw CometdSubscriptionModelError.clientIdNotValid
    }
  }
  
  // MARK: Helper
  ///  Create dictionary of model object, Subclasses should override method to return custom model
  open func toDictionary() throws -> [String: Any] {
    guard let clientId = clientId else {
      throw CometdSubscriptionModelError.clientIdNotValid
    }
    
    return [Bayeux.Channel.rawValue: bayeuxChannel.rawValue,
            Bayeux.ClientId.rawValue: clientId,
            Bayeux.Id.rawValue: id,
            Bayeux.Subscription.rawValue: subscriptionUrl]
  }
}

// MARK: Description
extension CometdSubscriptionModel: CustomStringConvertible {
  public var description: String {
    return "CometdSubscriptionModel: \(String(describing: try? self.toDictionary()))"
  }
}

// MARK: Equatable
public func ==(lhs: CometdSubscriptionModel, rhs: CometdSubscriptionModel) -> Bool {
  return lhs.hashValue == rhs.hashValue
}
