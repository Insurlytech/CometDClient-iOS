//
//  ModelBlockTuple.swift
//  
//  Created by Insurlytech on 19/05/2020.
//  Copyright © 2020 Insurlytech. All rights reserved.
//

import Foundation

// MARK: - ModelBlockTuple
public struct ModelBlockTuple {
  public let model: CometdSubscriptionModel
  public let block: ChannelSubscriptionBlock?
  
  public init(model: CometdSubscriptionModel, block: ChannelSubscriptionBlock?) {
    self.model = model
    self.block = block
  }
}
