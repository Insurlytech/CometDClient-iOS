//
//  CometdClientMessageResolverError.swift
//  
//
//  Created by Anthony Guiguen on 24/07/2020.
//

import Foundation

enum CometdClientMessageResolverError: Error {
  enum Constant {
    static let SIMPLE_UNMATCHED_LOGIN_PASSWORD = "SIMPLE_UNMATCHED_LOGIN_PASSWORD"
  }
  
  case subscription(subscription: String, reason: String)
  case handshake(json: [String: Any])
  
  var code: String {
    switch self {
    case .subscription:
      return "ERROR_COMETDCLIENT_MESSAGE_RESOLVER_SUBSCRIPTION"
    case .handshake(let json):
      return json[Bayeux.code.rawValue] as? String ?? "ERROR_COMETDCLIENT_MESSAGE_RESOLVER_HANDSHAKE"
    }
  }
  
  func toNSError() -> NSError {
    switch self {
    case .subscription(let subscription, let reason):
      return NSError(domain: ErrorConstant.domain, code: 11_000, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Subscription failed", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, comment: ""),
        ErrorConstant.code: "ERROR_COMETDCLIENT_MESSAGE_RESOLVER_SUBSCRIPTION",
        ErrorConstant.subscription: subscription
      ])
      
    case .handshake(let json):
      var codeNumber = 11_001
      switch self.code {
      case Constant.SIMPLE_UNMATCHED_LOGIN_PASSWORD:
        codeNumber = 403
      default: break
      }
      return NSError(domain: ErrorConstant.domain, code: codeNumber, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Hanshake failed", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(json[Bayeux.message.rawValue] as? String ?? "", comment: ""),
        ErrorConstant.code: self.code,
        ErrorConstant.context: json[Bayeux.context.rawValue] as? [String: Any] ?? [:]
      ])
    }
  }
}
