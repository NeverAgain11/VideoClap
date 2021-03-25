//
//  TimerProxy.swift
//  VideoClap
//
//  Created by lai001 on 2021/3/24.
//

import Foundation

public class TimerProxy: NSObject {
    
    public var timer: Timer?
    public var block: ((Timer) -> Void)?
    public var timeInterval: TimeInterval = .zero
    public var repeats: Bool = true
    
    public init(withTimeInterval timeInterval: TimeInterval, repeats: Bool, block: ((Timer) -> Void)?) {
        self.block = block
        self.repeats = repeats
        self.timeInterval = timeInterval
    }

    public func setupTimer() -> Timer {
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeats, block: { [weak self] (timer) in
                guard let self = self else { return }
                self.timerTick(timer)
            })
        } else {
            timer = Timer(timeInterval: timeInterval, target: self, selector: #selector(timerTick(_:)), userInfo: nil, repeats: repeats)
        }
        return timer.unsafelyUnwrapped
    }
    
    @objc private func timerTick(_ timer: Timer) {
        block?(timer)
    }

    public func invalidate() {
        timer?.invalidate()
        timer = nil
    }
    
}
