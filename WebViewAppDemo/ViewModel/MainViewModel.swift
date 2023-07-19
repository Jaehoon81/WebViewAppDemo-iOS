//
//  MainViewModel.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/22.
//

import Foundation
import Combine

class MainViewModel: NSObject {
    
    // 각각의 WebView와 NativeView 모두가 같은 ViewModel의 데이터를 공유하기 위해 Singleton 패턴으로 구현
    static let shared = MainViewModel()
    private override init() {
        super.init()
        print("MainViewModel_Init")
        
        employees = Employees(status: "", data: [])
        employeeList = Employees(status: "", data: [])
    }
    deinit {
        print("MainViewModel_Deinit")
    }
    
    // 각 화면의 활성화 상태를 저장 (하단 탭의 태그값 기준, 순서대로 f0, f1, f2, f3)
    var screenActiveStateArr: [Bool] = [false, false, false, false]
    
    // ReloadOtherTabs 액션을 실행 -> NativeVC에서 API 호출 -> 호출 결과를 구독된 WebVC에 Broadcast
    var employeesCallResult = PassthroughSubject<(Employees?), Error>()
    // ReloadOtherTabs 액션을 실행했을 경우, 해당 웹뷰의 TagId 저장
    var reloadActionTagId: String? = ""
    
    // ===================================================================================================
    // ViewModel의 Data Binding 방식 1: Listener(+ Combine)
    private(set) var employees: Employees! {
        didSet { employeesListener?(employees) }
    }
    @Published var employeesError: APIError?
    
    public typealias EmployeesListener = (Employees) -> Void
    private var employeesListener: EmployeesListener?
    
    func bindEmployeesListener(_ listener: EmployeesListener?) {
        employeesListener = listener
    }
    
    func getEmployeesAsync() async throws -> (Void) {
        do {
            if let employeesUrl = APIService.employeesUrl {
                let employees = try await APIService.shared.getEmployeeList(url: employeesUrl)
                if let employees = employees {
                    print("Obtained_Employees: \(employees)")
                    
                    self.employees = employees
                    employeesError = nil
                } else {
                    employeesError = APIError.emptyData
                    throw APIError.emptyData
                }
            }
        } catch {
            employeesError = APIError.networkFailure(429)
            throw APIError.networkFailure(429)
        }
    }
    
    // ===================================================================================================
    // ViewModel의 Data Binding 방식 2: Combine
    @Published var employeeList: Employees!
    private var cancelBags = Set<AnyCancellable>()
    
    func getEmployeeList1() {
        if let employeesUrl = APIService.employeesUrl {
            URLSession.shared.dataTaskPublisher(for: employeesUrl)
//                .print()
                .map(\.data)
                .decode(type: Employees.self, decoder: JSONDecoder())
                .replaceError(with: Employees(status: "error", data: []))
//                .eraseToAnyPublisher()
                .assign(to: \.employeeList, on: self)
                .store(in: &cancelBags)
        }
    }
    
    func getEmployeeList2() {
        if let employeesUrl = APIService.employeesUrl {
            APIService.shared.getEmployeeList(url: employeesUrl)
                .receive(on: DispatchQueue.main)
                .map { $0 }
                .sink { completion in
                    switch completion {
                    case .failure(let error): print("Failure: \(error.localizedDescription)")
                    case .finished: print("GetEmployeeList_Finished")
                    }
                } receiveValue: { [weak self] (employees) in
                    guard let strongSelf = self else { return }
                    if let employeeList = employees {
                        strongSelf.employeeList = employeeList
                    }
                }.store(in: &cancelBags)
        }
    }
}
