// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Foundation
import Combine
import GRDB
import GRDBCombine

/// An observable object that observes a database request and updates its `result` value with any changes
public class GRDBFetchHandler<FetchRequest: GRDBFetchRequest>: ObservableObject
{
	/// The result of the request. This is updated automatically with any changes.
	public var result: FetchRequest.Result
	{
		willSet
		{
			objectWillChange.send()
		}
	}

	public var fetchRequest: FetchRequest
	{
		didSet
		{
			setupPublisher()
		}
	}
	
	public var isLoadingInitialResult: Bool = true
	{
		willSet
		{
			if newValue != isLoadingInitialResult {
				objectWillChange.send()
			}
		}
	}

	private var database: DatabaseReader?

	private var subscription: AnyCancellable?
	private var publisher: AnyPublisher<FetchRequest.Result, Never>?

	public init(db: DatabaseReader, request: FetchRequest)
	{
		database = db
		result = request.defaultResult
		self.fetchRequest = request
		setupPublisher()
	}

	public static func placeholder<FetchRequest: GRDBFetchRequest>(fakeResult: FetchRequest.Result, request: FetchRequest) -> GRDBFetchHandler<FetchRequest>
	{
		GRDBFetchHandler<FetchRequest>(fakeResult: fakeResult, request: request)
	}

	private init(fakeResult: FetchRequest.Result, request: FetchRequest)
	{
		database = nil
		self.fetchRequest = request
		result = fakeResult
		isLoadingInitialResult = false
	}

	func setupPublisher()
	{
		guard let database = database else { return }
		publisher = ValueObservation
			.tracking(value: fetchRequest.defineRequest)
			.publisher(in: database)
			.replaceError(with: fetchRequest.defaultResult)
			.subscribe(on: DispatchQueue.main)
			.eraseToAnyPublisher()
		subscription = publisher?.sink { [weak self] result in
			self?.result = result
			self?.isLoadingInitialResult = false
		}
	}
}
