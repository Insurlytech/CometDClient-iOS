//
//  CometDClientRecorder.swift
//  
//
//  Created by Anthony Guiguen on 24/07/2020.
//

import Foundation

/// Implement  this protocol if you want to catch precise error for analytics or debug
public protocol CometDClientRecorder: class {
  /// This func is called for strategic error in this SDK.
  /// If you use this protocol you can call it for important error in your app or SDK.
  /// - Important: Be careful for duplicate calls for the same error
  /// - Parameters:
  ///   - error: To be precise have to pass NSError
  func record(error: NSError)
}
