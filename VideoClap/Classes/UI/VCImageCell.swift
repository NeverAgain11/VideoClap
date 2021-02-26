//
//  VCImageCell.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/18.
//

import Foundation
import SnapKit

open class VCImageCell: UICollectionViewCell {
    
    public var id: String = ""
    
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
