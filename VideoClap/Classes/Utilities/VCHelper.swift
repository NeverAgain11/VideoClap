//
//  VCHelper.swift
//  VideoClap
//
//  Created by lai001 on 2020/10/27.
//

import Foundation
import Metal

public class VCHelper: NSObject {
    
    internal static func getBundle() -> Bundle {
        let bundleName: String = "VideoClap"
        var bundle: Bundle?
        if let url = Bundle.main.url(forResource: "Frameworks/\(bundleName).framework/\(bundleName).bundle", withExtension: nil) {
            bundle = Bundle(url: url)
        }
        if bundle == nil, let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            bundle = Bundle(url: url)
        }
        return bundle ?? Bundle(for: VideoClap.self)
    }
    
    internal static func getDefaultMetallib() -> URL? {
        let bundleName: String = "VideoClap"
        var defaultMetallib: URL?
        
        if let frameworkUrl = Bundle.main.url(forResource: "Frameworks/\(bundleName).framework", withExtension: nil) {
            defaultMetallib = frameworkUrl.appendingPathComponent("default.metallib")
        }
        if defaultMetallib == nil, let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
            defaultMetallib = Bundle(url: url)?.url(forResource: "default", withExtension: "metallib")
        }
        return defaultMetallib
    }
    
    @available(iOS 11.0, *)
    internal static func metalKernel(functionName: String) -> CIKernel? {
        do {
            if let lib = VCHelper.getDefaultMetallib() {
                let data = try Data(contentsOf: lib)
                let kernel = try CIKernel(functionName: functionName, fromMetalLibraryData: data)
                return kernel
            } else {
                return nil
            }
        } catch let error {
            log.error(error)
            return nil
        }
    }
    
    public static func measure(fps: Bool = true) -> () -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        return {
            if fps {
                return 1.0 / (CFAbsoluteTimeGetCurrent() - start)
            } else {
                return CFAbsoluteTimeGetCurrent() - start
            }
        }
    }
    
}
