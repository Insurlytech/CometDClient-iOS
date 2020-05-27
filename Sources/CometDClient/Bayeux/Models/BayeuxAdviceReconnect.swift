//
//  BayeuxAdviceReconnect.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public enum BayeuxAdviceReconnect: String {
  case none = "none"
  case retry = "retry"
  case handshake = "handshake"
}
