//
//  EaseFunction.swift
//  VideoClap
//
//  Created by lai001 on 2021/2/8.
//

import Foundation

public protocol Ease {
    func `in`(_ x: CGFloat) -> CGFloat
    
    func out(_ x: CGFloat) -> CGFloat
    
    func inOut(_ x: CGFloat) -> CGFloat
}

public typealias EaseFunctionClosure = (CGFloat) -> CGFloat

public class EaseFunction {
    
    public struct Quadratic: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return x * x
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return -pow((x - 1.0), 2.0) + 1.0
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 2 * pow(x, 2)
            } else {
                return (-2 * pow(x, 2)) + (4 * x) - 1
            }
        }
    }
    
    public struct Cubic: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return pow(x, 3)
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return pow(x - 1, 3) + 1
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 4 * pow(x, 3)
            } else {
                return 1 / 2 * pow(2 * x - 2, 3) + 1
            }
        }
    }
    
    public struct Quartic: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return pow(x, 4)
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return pow(x - 1, 3) * (1 - x) + 1
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 8 * pow(x, 4)
            } else {
                return -8 * pow(x - 1, 4) + 1
            }
        }
    }
    
    public struct Quintic: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return pow(x, 5)
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return pow(x - 1, 5) + 1
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 16 * pow(x, 5)
            } else {
                return 1 / 2 * pow(2 * x - 2, 5) + 1
            }
        }
    }
    
    public struct Sine: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return sin((x - 1) * .pi / 2) + 1
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return sin(x * .pi / 2)
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            return 1 / 2 * (1 - cos(x * .pi))
        }
    }
    
    public struct Circular: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return 1 - sqrt(1 - pow(x, 2))
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return sqrt((2 - x) * x)
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                let h = 1 - sqrt(1 - 4 * x * x)
                return 1 / 2 * h
            } else {
                let f = 2 * x - 1
                let g = -(2 * x - 3) * f
                let h = sqrt(g)
                return 1 / 2 * (h + 1)
            }
        }
    }
    
    public struct Exponencial: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return x == 0 ? x : pow(2, 10 * (x - 1))
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return x == 1 ? x : 1 - pow(2, -10 * x)
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x == 0 || x == 1 {
                return x
            }
            
            if x < 1 / 2 {
                return 1 / 2 * pow(2, 20 * x - 10)
            } else {
                return -1 / 2 * pow(2, -20 * x + 10) + 1
            }
        }
    }
    
    public struct Elastic: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return sin(13 * .pi / 2 * x) * pow(2, 10 * (x - 1))
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return sin(-13 * .pi / 2 * (x + 1)) * pow(2, -10 * x) + 1
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 1 / 2 * sin((13 * .pi / 2) * 2 * x) * pow(2, 10 * ((2 * x) - 1))
            } else {
                return 1 / 2 * (sin(-13 * .pi / 2 * ((2 * x - 1) + 1)) * pow(2, -10 * (2 * x - 1)) + 2)
            }
        }
    }
    
    public struct Bounce: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return 1 - out(1 - x)
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            if x < 4 / 11 {
                return (121 * x * x) / 16
            } else if x < 8 / 11 {
                let f = (363 / 40) * x * x
                let g = (99 / 10) * x
                return f - g + (17 / 5)
            } else if x < 9 / 10 {
                let f = (4356 / 361) * x * x
                let g = (35442 / 1805) * x
                return  f - g + 16061 / 1805
            } else {
                let f = (54 / 5) * x * x
                return f - ((513 / 25) * x) + 268 / 25
            }
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                return 1 / 2 * `in`(2 * x)
            } else {
                let f = out(x * 2 - 1) + 1
                return 1 / 2 * f
            }
        }
    }
    
    public struct Back: Ease {
        public func `in`(_ x: CGFloat) -> CGFloat {
            return x * x * x - x * sin(x * .pi)
        }
        
        public func out(_ x: CGFloat) -> CGFloat {
            return 1 - ( pow(1 - x, 3) - (1 - x) * sin((1 - x) * .pi))
        }
        
        public func inOut(_ x: CGFloat) -> CGFloat {
            if x < 1 / 2 {
                let g = pow(2 * x, 3) - 2 * x * sin(2 * x * .pi)
                return 1 / 2 * g
            } else {
                let divide = pow(1 - (2 * x - 1), 3) - (1 - (2 * x - 1)) * sin((1 - (2 * x - 1)) * .pi)
                return 1 / 2 * (1 - divide) + 1 / 2
            }
        }
    }
    
}
