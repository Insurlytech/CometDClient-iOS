//
//  CometDClientError.swift
//  
//
//  Created by Anthony Guiguen on 27/05/2020.
//

import Foundation

public enum HandshakeError: Error {
  case wrongCredential
}

public enum CometDClientError: Error {
  case lostConnection, write, subscription, handshake(reason: HandshakeError?)
}
