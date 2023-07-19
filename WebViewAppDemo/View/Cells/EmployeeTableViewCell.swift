//
//  EmployeeTableViewCell.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/13.
//

import Foundation
import UIKit

class EmployeeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var employeeIdLabel: UILabel!
    @IBOutlet weak var employeeNameLabel: UILabel!
    
//    var employee: EmployeeData? {
//        didSet {
//            employeeIdLabel.text = String(describing: employee?.id)
//            employeeNameLabel.text = employee?.employeeName
//        }
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
