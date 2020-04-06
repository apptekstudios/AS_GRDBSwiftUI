//
//  File.swift
//  
//
//  Created by Toby Brennan on 6/4/20.
//

import Combine
import GRDB
import GRDBCombine

/// An observable object that observes a database request and updates its `result` value with any changes
public class GRDBFetchHandler<FetchRequest: GRDBFetchRequest>: ObservableObject {
	/// The result of the request. This is updated automatically with any changes.
	public var result: FetchRequest.Result {
		willSet {
			objectWillChange.send()
		}
	}
	
	public var request: FetchRequest {
		didSet {
			setupPublisher()
		}
	}
	
	private var database: DatabaseReader?
	
	private var subscription: AnyCancellable?
	private var publisher: AnyPublisher<FetchRequest.Result, Never>?
	
	public init(db: DatabaseReader, request: FetchRequest) {
		self.database = db
		self.result = request.defaultResult
		self.request = request
		setupPublisher()
	}
	
	public static func placeholder<FetchRequest: GRDBFetchRequest>(fakeResult: FetchRequest.Result, request: FetchRequest) -> GRDBFetchHandler<FetchRequest> {
		return GRDBFetchHandler<FetchRequest>(fakeResult: fakeResult, request: request)
	}
	
	private init(fakeResult: FetchRequest.Result, request: FetchRequest) {
		self.database = nil
		self.request = request
		self.result = fakeResult
	}
	
	func setupPublisher() {
		guard let database = database else { return }
		self.publisher = ValueObservation
			.tracking(value: request.request)
			.publisher(in: database)
			.replaceError(with: request.defaultResult)
			.eraseToAnyPublisher()
		self.subscription = publisher?.sink { [weak self] result in
			self?.result = result
		}
	}
}
