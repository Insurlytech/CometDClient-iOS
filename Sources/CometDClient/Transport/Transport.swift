//
//  Transport.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

// MARK: - Transport
public protocol Transport {
  var isConnected: Bool { get }
  
  func writeString(_ aString: String)
  func openConnection()
  func closeConnection()
}

public protocol TransportDelegate: class {
  func didConnect()
  func didFailConnection(_ error: Error?)
  func didDisconnect(_ error: Error?)
  func didWriteError(_ error: Error?)
  func didReceiveMessage(_ text: String)
  func didReceivePong()
}
