//
//  APIService.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/19.
//

import Foundation
import Combine

class APIService: NSObject {
    
    static let shared = APIService()
    private override init() { }
    
    static let employeesUrl = URL(string: "http://dummy.restapiexample.com/api/v1/employees")
    private var cancelBags = Set<AnyCancellable>()
    
    func getEmployeeList(url: URL) async throws -> (Employees?) {
        typealias PostContinuation = CheckedContinuation<(Employees?), Error>
        
        return try await withCheckedThrowingContinuation({ (continuation: PostContinuation) in
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                if let data = data {
                    let employees = try? JSONDecoder().decode(Employees.self, from: data)
                    if let employees = employees {
                        continuation.resume(returning: employees)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }.resume()
        })
    }
    
    func getEmployeeList(url: URL) -> AnyPublisher<(Employees?), Error> {
        return Future { [weak self] (promise) in
            guard let strongSelf = self else { return }
            URLSession.shared.dataTaskPublisher(for: url)
                .retry(1)
                .mapError { $0 }
                .tryMap { (element) -> Data in
                    guard let response = element.response as? HTTPURLResponse,
                        response.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return element.data
                }
                .decode(type: Employees.self, decoder: JSONDecoder())
                .replaceError(with: Employees(status: "error", data: []))
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { employees in
                    promise(.success(employees))
                }
                .store(in: &strongSelf.cancelBags)
        }
        .eraseToAnyPublisher()
    }
}
