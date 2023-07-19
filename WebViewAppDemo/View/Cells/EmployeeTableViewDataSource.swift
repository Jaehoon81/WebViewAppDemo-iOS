//
//  EmployeeTableViewDataSource.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/19.
//

import Foundation
import UIKit

class EmployeeTableViewDataSource<CELL: UITableViewCell, T>: NSObject, UITableViewDataSource {
    
    private var identifier: String!
    private var items: [T]!
    private var configuration: (CELL, T) -> () = { _, _ in }
    
    init(with identifier: String, items: [T], configuration: @escaping (CELL, T) -> ()) {
        self.identifier = identifier
        self.items = items
        self.configuration = configuration
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CELL
        let item = items[indexPath.row]
        
        configuration(cell, item)
        return cell
    }
}
