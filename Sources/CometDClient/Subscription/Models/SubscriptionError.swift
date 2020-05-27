//
//  SubscriptionError.swift
//  
//
//  Created by Anthony Guiguen on 27/05/2020.
//

import Foundation

public enum SubscriptionError: Error {
  case error(subscription: String, error: String)
}
