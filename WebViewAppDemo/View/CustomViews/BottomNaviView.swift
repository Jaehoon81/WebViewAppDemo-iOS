//
//  BottomNaviView.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/22.
//

import Foundation
import UIKit
import SnapKit

class BottomNaviView: UIView {
    
    @IBOutlet weak var bottomTab1: UIView!
    @IBOutlet weak var bottomTab2: UIView!
    @IBOutlet weak var bottomTab3: UIView!
    @IBOutlet weak var bottomTab4: UIView!
    
    @IBOutlet weak var bottomTab1_defaultImage: UIImageView!
    @IBOutlet weak var bottomTab2_defaultImage: UIImageView!
    @IBOutlet weak var bottomTab3_defaultImage: UIImageView!
    @IBOutlet weak var bottomTab4_defaultImage: UIImageView!
    
    @IBOutlet weak var bottomTab1_pressedImage: UIImageView!
    @IBOutlet weak var bottomTab2_pressedImage: UIImageView!
    @IBOutlet weak var bottomTab3_pressedImage: UIImageView!
    @IBOutlet weak var bottomTab4_pressedImage: UIImageView!
    
    @IBOutlet weak var bottomTab1_label: UILabel!
    @IBOutlet weak var bottomTab2_label: UILabel!
    @IBOutlet weak var bottomTab3_label: UILabel!
    @IBOutlet weak var bottomTab4_label: UILabel!
    
    private var selectedIndex: Int = 0
    
    public typealias SelectionHandler = (_ sender: BottomNaviView, _ index: Int) -> ()
    private var selectionHandler: SelectionHandler?
    
    func addSelectListener(handler: @escaping SelectionHandler) {
        selectionHandler = handler
    }
    
    deinit {
        
    }
    
    init(frame: CGRect, parentView: UIView) {
        super.init(frame: frame)
        setupXib()
        
        parentView.addSubview(self)
        self.snp.removeConstraints()
        self.snp.makeConstraints { make in
//            make.top.equalTo(parentView.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(parentView.snp.bottom)
            make.width.equalTo(parentView.snp.width)
            make.height.equalTo(70)
        }
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(handleBottomTabs(sender:)))
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(handleBottomTabs(sender:)))
        let tapGesture3 = UITapGestureRecognizer(target: self, action: #selector(handleBottomTabs(sender:)))
        let tapGesture4 = UITapGestureRecognizer(target: self, action: #selector(handleBottomTabs(sender:)))
        tapGesture1.name = "bottomTab1"
        tapGesture2.name = "bottomTab2"
        tapGesture3.name = "bottomTab3"
        tapGesture4.name = "bottomTab4"
        
        bottomTab1.addGestureRecognizer(tapGesture1)
        bottomTab2.addGestureRecognizer(tapGesture2)
        bottomTab3.addGestureRecognizer(tapGesture3)
        bottomTab4.addGestureRecognizer(tapGesture4)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupXib()
    }
    
    private func setupXib() {
        let view = Bundle.main.loadNibNamed("BottomNaviView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
    }
    
    @objc func handleBottomTabs(sender: UITapGestureRecognizer) {
        if let bottomTab = sender.name {
            print("handleBottomTabs" + "\(bottomTab.substring(from: 9, to: 9))" + "(sender:)")
            
            switch bottomTab {
            case "bottomTab1": selectBottomTab(index: 0)
            case "bottomTab2": selectBottomTab(index: 1)
            case "bottomTab3": selectBottomTab(index: 2)
            case "bottomTab4": selectBottomTab(index: 3)
            default: selectBottomTab(index: -1)
            }
        }
    }
    
    func selectBottomTab(index: Int) {
        guard index >= 0 else { return }
        selectedIndex = index
        
        let defaultImageArr = [bottomTab1_defaultImage, bottomTab2_defaultImage, bottomTab3_defaultImage, bottomTab4_defaultImage]
        let pressedImageArr = [bottomTab1_pressedImage, bottomTab2_pressedImage, bottomTab3_pressedImage, bottomTab4_pressedImage]
        for defaultImage in defaultImageArr {
            defaultImage?.isHidden = false
        }
        for pressedImage in pressedImageArr {
            pressedImage?.isHidden = true
        }
        defaultImageArr[index]?.isHidden = true
        pressedImageArr[index]?.isHidden = false
        
        let labelArr = [bottomTab1_label, bottomTab2_label, bottomTab3_label, bottomTab4_label]
        for label in labelArr {
            label?.textColor = .darkGray
        }
        labelArr[index]?.textColor = .systemIndigo
        
        selectionHandler?(self, selectedIndex)
    }
}
