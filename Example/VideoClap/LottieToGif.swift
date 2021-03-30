//
//  LottieToGif.swift
//  VideoClap_Example
//
//  Created by lai001 on 2021/3/10.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import VideoClap
import FLAnimatedImage

class LottieToGif: UIViewController {
    
    lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    lazy var imageView: FLAnimatedImageView = {
        let view = FLAnimatedImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.minimumIntegerDigits = 1
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf
    }()
    
    var cancel: (() -> Void)?
    
    deinit {
        cancel?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(progressLabel)
        view.addSubview(imageView)
        progressLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let gif = VCLottieToGIF()
        let targetURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("test.gif"))
        guard let jsonURL = resourceURL(filename: "MotionCorpse-Jrcanest.json") else { return }
        
        cancel = gif.createGif(jsonURL: jsonURL, url: targetURL, autoRemove: true) { (frameSize) -> CGSize in
            return CGSize(width: 600, height: 600)
        } fpsClosure: { (frameRate) -> Double in
            return 60
        } progessCallback: { [weak self] (progress) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.progressLabel.text = self.nf.string(from: NSNumber(value: progress))
            }
        } closure: { [weak self] (error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.progressLabel.isHidden = true
                self.imageView.sd_setImage(with: targetURL, completed: nil)
                if let _error = error {
                    self.progressLabel.text = _error.localizedDescription
                    self.progressLabel.isHidden = false
                }
            }
        }
    }
    
}
