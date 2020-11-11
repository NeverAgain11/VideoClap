//
//  TestWindow.swift
//  CopyData
//
//  Created by 赖敏聪 on 2020/9/4.
//  Copyright © 2020 赖敏聪. All rights reserved.
//

import UIKit

let TransitionNotification = NSNotification.Name(rawValue: "Transition")

enum TransitionType: String, CaseIterable {
    case Alpha
    case BarsSwipe
    case Blur
    case CopyMachine
    case Dissolve
    case Flip
    case IceMelting
    case Slide
    case Swirl
    case Vortex
    case Wave
    case Wipe
    case Windowslice
    case PageCurl
    case Doorway
    case Squareswire
    case Mod
    case Cube
    case Translation
}

class TestWindow: UIWindow {
    
    lazy var button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .brown
        button.layer.cornerRadius = 64 / 2
        button.addTarget(self, action: #selector(buttonDidTap), for: .touchUpInside)
        let gr = UIPanGestureRecognizer(target: self, action: #selector(pan))
        button.addGestureRecognizer(gr)
        return button
    }()
    
    lazy var tableView: UITableView = {
        let tableview = UITableView(frame: .zero, style: .plain)
        tableview.backgroundColor = .white
        tableview.rowHeight = 54
        tableview.isHidden = true
        tableview.bounces = false
        tableview.delegate = self
        tableview.dataSource = self
        tableview.tableFooterView = UIView()
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "C")
        return tableview
    }()
    
    lazy var titles: [TransitionType] = {
        
        return TransitionType.allCases
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
        addSubview(button)
        
        button.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.size.equalTo(64)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bringSubviewToFront(tableView)
        bringSubviewToFront(button)
    }
    
    @objc func buttonDidTap(_ sender: UIButton) {
        tableView.isHidden = !tableView.isHidden
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        self.button.center = sender.location(in: self)
    }
    
}

extension TestWindow: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "C", for: indexPath)
        cell.textLabel?.text = titles[indexPath.item].rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: TransitionNotification, object: nil, userInfo: ["transitionType":titles[indexPath.item]])
        tableView.isHidden = true
    }
    
}
