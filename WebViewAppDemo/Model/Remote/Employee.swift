//
//  Employee.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/19.
//

import Foundation

struct Employees: Codable {
    
    let status: String
    let data: [EmployeeData]
}

struct EmployeeData: Codable {
    
    let id: Int
    let employeeName: String
    let employeeAge: Int
    let employeeSalary: Int
    let profileImage: String
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case employeeName = "employee_name"
        case employeeAge = "employee_age"
        case employeeSalary = "employee_salary"
        case profileImage = "profile_image"
    }
}
