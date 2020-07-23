//
//  CometDClientError.swift
//  
//
//  Created by Anthony Guiguen on 27/05/2020.
//

import Foundation

public enum CometDClientError: Error {
  case lostConnection(error: WebsocketTransportError), write(error: WebsocketTransportError)
  case subscription(subscription: String, reason: String)
  case handshake(error: [String: Any])
  
  public var code: String {
    switch self {
    case .lostConnection(let error), .write(let error): return error.code
    case .subscription:
      return "ERROR_COMETDCLIENT_SUBSCRIPTION"
    case .handshake(let error):
      return error[Bayeux.code.rawValue] as? String ?? "ERROR_COMETDCLIENT_HANDSHAKE"
    }
  }
  
  public func toNSError() -> NSError {
    switch self {
    case .lostConnection(let error): return error.toNSError()
    case .write(let error): return error.toNSError()
    case .subscription(let subscription, let reason):
      return NSError(domain: ErrorConstant.domain, code: 11_000, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Subscription failed", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, comment: ""),
        ErrorConstant.code: code,
        ErrorConstant.subscription: subscription
      ])
      
    case .handshake(let error):
      var code = 11_001
      switch self.code {
      case "SIMPLE_UNMATCHED_LOGIN_PASSWORD":
        code = 403
      default: break
      }
      return NSError(domain: ErrorConstant.domain, code: code, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Hanshake failed", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(error[Bayeux.message.rawValue] as? String ?? "", comment: ""),
        ErrorConstant.code: self.code,
        ErrorConstant.context: error[Bayeux.context.rawValue] as? [String: Any] ?? [:]
      ])
    }
  }
}
