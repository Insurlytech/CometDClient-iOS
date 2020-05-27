//
//  BayeuxChannel.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public enum BayeuxChannel: String {
  case handshake = "/meta/handshake"
  case connect = "/meta/connect"
  case disconnect = "/meta/disconnect"
  case subscribe = "/meta/subscribe"
  case unsubscibe = "/meta/unsubscribe"
}
