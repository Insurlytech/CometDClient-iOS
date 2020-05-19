//
//  CometdSocketError.swift
//
//  Created by Insurlytech on 19/04/2019.
//  Copyright © 2020 Insurlytech. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

// MARK: - CometdSocketError
public enum CometdSocketError: Error {
  case lostConnection
  case transportWrite
}
