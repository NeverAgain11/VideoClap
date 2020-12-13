//
//  TestTimeScaleView.swift
//  VideoClap_Example
//
//  Created by lai001 on 2020/12/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import VideoClap

class TestTimeScaleView: UIViewController {
    
    lazy var timeScaleView: VCTimeScaleView = {
        let view = VCTimeScaleView()
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
}

extension TestTimeScaleView {
    
    func setupUI() {
        view.addSubview(timeScaleView)
        setupConstraints()
    }
    
    func setupConstraints() {
        timeScaleView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(160)
            make.height.equalTo(100)
        }
    }
    
}
