//
//  ValueMap.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/28.
//

import Foundation

extension CGFloat {

    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }
    
    func map(from: ClosedRange<CGFloat>, to: Range<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }
    
    func map(from: Range<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }
    
    func map(from: Range<CGFloat>, to: Range<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }

}

extension Double {
    
    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> Double {
        return Double(CGFloat(self).map(from: from, to: to))
    }

}

extension Float {
    
    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> Double {
        return Double(CGFloat(self).map(from: from, to: to))
    }

}
