//
//  VCTimeScaleCell.swift
//  VideoClap
//
//  Created by lai001 on 2020/12/22.
//

import Foundation
import AVFoundation
import SnapKit

public class VCTimeScaleCell: UICollectionViewCell {
    
    public lazy var dotLabel: UILabel = {
        let label = UILabel()
        label.text = "・"
        label.textColor = UIColor.lightText
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 9, weight: .medium)
        label.textColor = #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return label
    }()
    
    public lazy var keyTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightText
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 9, weight: .medium)
        label.textColor = #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dotLabel)
        contentView.addSubview(keyTimeLabel)
        dotLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        keyTimeLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(contentView.snp.left)
            make.centerY.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
