// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Combine
import Foundation
import GRDB
import GRDBCombine
import SwiftUI

/// An dynamic property wrapper that observes a database request and updates its value with any changes
@propertyWrapper
public struct GRDBFetch<FetchRequest: GRDBFetchRequest>: DynamicProperty
{
	@ObservedObject
	var handler: GRDBFetchHandler<FetchRequest>
	
	//@Environment(\.grdbDatabaseReader)
	//var databaseReader

	public var wrappedValue: FetchRequest.Result
	{
		handler.result
	}

	public init(db: DatabaseReader, request: FetchRequest)
	{
		handler = GRDBFetchHandler(db: db, request: request)
	}

	// Use this init to mock a fetch request, returning a specific result (eg. useful while designing a view)
	public init<Result>(placeholderResult: Result) where FetchRequest == PlaceholderFetchRequest<Result>
	{
		handler = GRDBFetchHandler<PlaceholderFetchRequest<Result>>.placeholder(fakeResult: placeholderResult)
	}

	public var request: FetchRequest
	{
		get { handler.fetchRequest }
		nonmutating set { handler.fetchRequest = newValue }
	}

	public var isLoadingInitialResult: Bool
	{
		handler.isLoadingInitialResult
	}

	public var projectedValue: Self
	{
		self
	}
}

class GRDBFetchHandler<FetchRequest: GRDBFetchRequest>: ObservableObject
{
	/// The result of the request. This is updated automatically with any changes.
	var result: FetchRequest.Result
	{
		willSet
		{
			objectWillChange.send()
		}
	}

	var fetchRequest: FetchRequest
	{
		didSet
		{
			setupPublisher()
		}
	}

	var isLoadingInitialResult: Bool = true
	{
		willSet
		{
			if newValue != isLoadingInitialResult
			{
				objectWillChange.send()
			}
		}
	}

	private var database: DatabaseReader?

	private var subscription: AnyCancellable?
	private var publisher: AnyPublisher<FetchRequest.Result, Never>?

	init(db: DatabaseReader, request: FetchRequest)
	{
		database = db
		result = request.defaultResult
		fetchRequest = request
		setupPublisher()
	}

	static func placeholder<Result>(fakeResult: Result) -> GRDBFetchHandler<PlaceholderFetchRequest<Result>>
	{
		GRDBFetchHandler<PlaceholderFetchRequest<Result>>(placeholderResult: fakeResult)
	}

	private init<Result>(placeholderResult: Result) where FetchRequest == PlaceholderFetchRequest<Result>
	{
		database = nil
		fetchRequest = PlaceholderFetchRequest(defaultResult: placeholderResult)
		result = placeholderResult
		isLoadingInitialResult = false
	}

	func setupPublisher()
	{
		guard let database = database else { return }
		publisher = ValueObservation
			.tracking(value: fetchRequest.onRead)
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
