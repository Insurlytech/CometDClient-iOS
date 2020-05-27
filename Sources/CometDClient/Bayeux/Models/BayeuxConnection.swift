//
//  BayeuxConnection.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public enum BayeuxConnection: String {
  case longPolling = "long-polling"
  case callback = "callback-polling"
  case iFrame = "iframe"
  case webSocket = "websocket"
}
