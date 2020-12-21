//
//  PinchGRHandler.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/21.
//

import Foundation
import UIKit

public protocol PinchGRHandler: NSObject {
    func handle(state: UIGestureRecognizer.State, scale: CGFloat)
}
