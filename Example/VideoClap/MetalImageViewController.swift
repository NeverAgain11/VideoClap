//
//  MetalImageViewController.swift
//  VideoClap_Example
//
//  Created by lai001 on 2021/3/9.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import VideoClap

class MetalImageViewController: UIViewController {
    
    lazy var imageView: MetalImageView = {
        let view = MetalImageView()
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let imageURL = resourceURL(filename: "test1.jpg"), let image = CIImage(contentsOf: imageURL) {
            imageView.image = image
            imageView.metalContentMode = .scaleAspectFit
            imageView.redraw()
        }
    }
    
}
