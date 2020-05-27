//
//  CometdSubscriptionState.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public enum CometdSubscriptionState {
  case pending(CometdSubscriptionModel)
  case subscribed(CometdSubscriptionModel)
  case queued(CometdSubscriptionModel)
  case subscribingTo(CometdSubscriptionModel)
  case unknown(CometdSubscriptionModel?)
  
  public var isSubscribingTo: Bool {
    switch self {
    case .subscribingTo:
      return true
    default:
      return false
    }
  }
  
  public var model: CometdSubscriptionModel? {
    switch self {
    case .pending(let model),
         .subscribed(let model),
         .queued(let model),
         .subscribingTo(let model),
         .unknown(let model?):
      return model
    default:
      return nil
    }
  }
}
