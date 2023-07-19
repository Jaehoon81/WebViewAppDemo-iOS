//
//  NativeViewController.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/13.
//

import UIKit
import Combine

class NativeViewController: UIViewController {
    
    @IBOutlet weak var employeeTableView: UITableView!
    
    private var employeeDataSource: EmployeeTableViewDataSource<EmployeeTableViewCell, EmployeeData>!
    private var employeeTaskHandler: Task<(Void), Error>?
    
    var mainViewModel: MainViewModel!
    private var cancelBags = Set<AnyCancellable>()
    
    var tagId: String?
    var scrollDelegate: ScrollDelegate?
    
    private var isEmployeeTaskProcess: Bool = false  // true or false로 작업방식 결정
    private var isFirstApiCallSuccess: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("NativeViewController:: " + #function + "_\(String(describing: tagId))")
        
        mainViewModel = MainViewModel.shared
        mainViewModel.screenActiveStateArr[Int((tagId?.substring(from: 1, to: 1))!)!] = true
        setupObservers()
        
        if isEmployeeTaskProcess == true {
            employeeTaskHandler?.cancel()
            executeEmployeeTask()
        } else {
            obtainEmployeeList()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("NativeViewController:: " + #function + "_\(String(describing: tagId))")
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("NativeViewController:: " + #function + "_\(String(describing: tagId))")
        
    }
    
    func releaseResources() {
        print("NativeViewController:: " + #function + "_\(String(describing: tagId))")
        
    }
    
    private func setupObservers() {
        // ViewModel의 Data Binding 방식 1: Listener(+ Combine)
        mainViewModel.bindEmployeesListener { [weak self] (employees) in
            self?.updateEmployeeDataSource(employees)
        }
        mainViewModel.$employeesError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (error) in
                if let error = error {
                    print("Employees_Error: \(String(describing: error.errorMessage))")
                    
                    CommonUtils.showAlert(targetVC: self, message: "API 호출 에러!!")
                    // API 호출 결과를 구독된 WebVC에 Broadcast (API호출 실패 시)
//                    self?.mainViewModel.employeesCallResult.send(completion: .failure(error))
                    self?.mainViewModel.employeesCallResult.send(Employees(status: "error", data: []))
                }
            }.store(in: &cancelBags)
        
        // ViewModel의 Data Binding 방식 2: Combine
        mainViewModel.$employeeList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (employeeList) in
                if let employees = employeeList {
                    if employees.status == "error" {
                        CommonUtils.showAlert(targetVC: self, message: "API 호출 에러!!")
                        // API 호출 결과를 구독된 WebVC에 Broadcast (API호출 실패 시)
                        self?.mainViewModel.employeesCallResult.send(employees)
                        
                    } else if employees.status == "success" {
                        self?.updateEmployeeDataSource(employees)
                    }
                }
            }.store(in: &cancelBags)
    }
    
    private func updateEmployeeDataSource(_ employees: Employees) {
        employeeDataSource = EmployeeTableViewDataSource(with: "EmployeeTableViewCell", items: employees.data, configuration: { (cell, employeeData) in
            
            cell.employeeIdLabel.text = String(describing: employeeData.id)
            cell.employeeNameLabel.text = employeeData.employeeName
        })
        DispatchQueue.main.async {
            self.employeeTableView.delegate = self
            self.employeeTableView.bounces = false
            self.employeeTableView.dataSource = self.employeeDataSource
            self.employeeTableView.reloadData()
            
            if self.isFirstApiCallSuccess == false {
                self.isFirstApiCallSuccess = true
                self.scrollDelegate?.didScroll(isUp: false)
            }
            CommonUtils.showAlert(targetVC: self, message: "API 호출 성공!!")
            // API 호출 결과를 구독된 WebVC에 Broadcast (API호출 성공 시)
            self.mainViewModel.employeesCallResult.send(employees)
        }
    }
    
    private func executeEmployeeTask() {
        // ViewModel의 Data Binding 방식 1: Listener(+ Combine)
        employeeTaskHandler = Task(priority: .background) {
            do {
                await Task.yield()
                try await mainViewModel.getEmployeesAsync()
                await Task.yield()
                print("Getting the employee list is done.")
            } catch {
                print(#function + " withException: \(error.localizedDescription)")
            }
        }
    }
    
    private func obtainEmployeeList() {
        // ViewModel의 Data Binding 방식 2: Combine
        // 네트워크 통신 방법 1
//        mainViewModel.getEmployeeList1()
        
        // 네트워크 통신 방법 2
        mainViewModel.getEmployeeList2()
    }
    
    func refreshNativeView() {
        if employeeTableView != nil {
            if isEmployeeTaskProcess == true {
                employeeTaskHandler?.cancel()
                executeEmployeeTask()
            } else {
                obtainEmployeeList()
            }
        } else {
            print("NativeView_\(String(describing: tagId)) is not ready yet.")
        }
    }
}

extension NativeViewController: /*UIScrollViewDelegate, */UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0.0 {
            scrollDelegate?.didScroll(isUp: true)
        } else {
            scrollDelegate?.didScroll(isUp: false)
        }
    }
}
