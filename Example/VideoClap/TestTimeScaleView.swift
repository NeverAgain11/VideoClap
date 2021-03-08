//
//  TestTimeScaleView.swift
//  VideoClap_Example
//
//  Created by lai001 on 2020/12/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import VideoClap
import AVFoundation

class TestTimeScaleView: UIViewController {
    
    lazy var timeScaleView: VCTimeScaleScrollView = {
        let view = VCTimeScaleScrollView()
        view.backgroundColor = UIColor.lightGray
        return view
    }()
    
    internal lazy var pinchGR: UIPinchGestureRecognizer = {
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGRHandler(_:)))
        return pinchGR
    }()
    
    lazy var vView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 2
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        timeScaleView.contentInset.left = timeScaleView.bounds.width / 2.0
        timeScaleView.contentInset.right = timeScaleView.contentInset.left
        
        timeScaleView.setTime(currentTime: .zero, duration: CMTime(seconds: 100, preferredTimescale: 600))
        timeScaleView.setScale(60)
        
        view.addGestureRecognizer(pinchGR)
        
        timeScaleView.didScrollCallback = { time in
            LLog(time.seconds)
        }
    }
    
    @objc internal func pinchGRHandler(_ sender: UIPinchGestureRecognizer) {
        timeScaleView.handle(state: sender.state, scale: sender.scale)
        
        if sender.state == .changed {
            sender.scale = 1.0
        }
    }
    
}

extension TestTimeScaleView {
    
    func setupUI() {
        view.addSubview(timeScaleView)
        view.addSubview(vView)
        setupConstraints()
    }
    
    func setupConstraints() {
        timeScaleView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(160)
            make.height.equalTo(100)
        }
        
        vView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.height.equalTo(120)
            make.centerY.equalTo(timeScaleView)
        }
    }
    
}
