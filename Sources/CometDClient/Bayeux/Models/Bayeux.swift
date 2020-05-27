//
//  Bayeux.swift
//  
//
//  Created by Anthony Guiguen on 22/05/2020.
//

import Foundation

public enum Bayeux: String {
  case channel = "channel"
  case version = "version"
  case clientId = "clientId"
  case connectionType = "connectionType"
  case data = "data"
  case subscription = "subscription"
  case id = "id"
  case minimumVersion = "minimumVersion"
  case supportedConnectionTypes = "supportedConnectionTypes"
  case successful = "successful"
  case error = "error"
  case advice = "advice"
  case ext = "ext"
}
