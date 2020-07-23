//
//  File.swift
//  
//
//  Created by Anthony Guiguen on 22/07/2020.
//

import Foundation

public enum WebsocketTransportError: Error {
  case noLongerViable, cancelled, disconnected(reason: String, code: Int), write(error: Error?)
  
  public var code: String {
    switch self {
    case .noLongerViable:
      return "ERROR_WS_NO_LONGER_VIABLE"
    case .cancelled:
      return "ERROR_WS_CANCELED"
    case .write:
      return "ERROR_WS_WRITE"
    case .disconnected:
      return "ERROR_WS_DISCONNECTED"
    }
  }
  
  public func toNSError() -> NSError {
    switch self {
    case .noLongerViable:
      return NSError(domain: ErrorConstant.domain, code: 10_000, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("No longer viable connection", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString("WebsocketTransport receive no longer viable connection", comment: ""),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Try to reconnect if needed", comment: ""),
        ErrorConstant.code: code
      ])
    case .cancelled:
      return NSError(domain: ErrorConstant.domain, code: 10_001, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Connection cancelled", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString("WebsocketTransport receive cancelled connection", comment: ""),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Try to reconnect if needed", comment: ""),
        ErrorConstant.code: code
      ])
    case .disconnected(let reason, let code):
      return NSError(domain: ErrorConstant.domain, code: code, userInfo: [
        NSLocalizedDescriptionKey: NSLocalizedString("Disconnected", comment: ""),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, comment: ""),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Try to reconnect if needed", comment: ""),
        ErrorConstant.code: code
      ])
    case .write(let error):
      if let error = error as NSError? {
        return error
      } else {
        return NSError(domain: ErrorConstant.domain, code: 10_002, userInfo: [
          NSLocalizedDescriptionKey: NSLocalizedString("Write error", comment: ""),
          ErrorConstant.code: code
        ])
      }
    }
  }
}
