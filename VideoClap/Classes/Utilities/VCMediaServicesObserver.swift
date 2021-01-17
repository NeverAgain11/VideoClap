//
//  VCMediaServicesObserver.swift
//  VideoClap
//
//  Created by laimincong on 2021/1/17.
//

import Foundation

public protocol VCMediaServicesObserver {
    
    func mediaServicesWereResetNotification(_ sender: Notification)
    
    func mediaServicesWereLostNotification(_ sender: Notification)
    
}
