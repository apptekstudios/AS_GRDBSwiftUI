// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Combine
import Foundation
import GRDB
import GRDBCombine
import os.log
import SwiftUI

/// An dynamic property wrapper that observes a database request and updates its value with any changes
@propertyWrapper
public struct GRDBFetch<FetchRequest: GRDBFetchRequest>: DynamicProperty
{
	@ObservedObject
	var handler: GRDBFetchHandler<FetchRequest>

	@Environment(\.grdbDatabaseReader)
	var databaseReader

	/// The result of the fetch
	public var wrappedValue: FetchRequest.Result
	{
		handler.result
	}

	/// Create a fetch with the given request. Set animateUpdates to determine whether any updates from the database will be animated
	public init(request: FetchRequest, animateUpdates: Bool = true)
	{
		handler = GRDBFetchHandler(db: nil, request: request, animateUpdates: animateUpdates)
	}

	/// Use this init to mock a fetch request, returning a specific result (eg. useful while designing a view)
	public init<Result>(placeholderResult: Result) where FetchRequest == PlaceholderFetchRequest<Result>
	{
		handler = GRDBFetchHandler<PlaceholderFetchRequest<Result>>.placeholder(fakeResult: placeholderResult)
	}

	public var request: FetchRequest
	{
		get { handler.fetchRequest }
		nonmutating set {
			handler.fetchRequest = newValue
		}
	}

	/// This variable reflects whether the first result has been recieved (useful for showing loading indicator initially if your query is expected to be slow)
	public var isLoadingInitialResult: Bool
	{
		handler.isLoadingInitialResult
	}

	/// Set this variable to enable/disable animation of updates to the database fetch result
	public var animateUpdates: Bool
	{
		get { handler.animateUpdates }
		nonmutating set { handler.animateUpdates = newValue }
	}

	/// Call this function to temporarily enable/disable animation for the next database update recieved
	public func animateNextUpdate(_ animate: Bool = true)
	{
		handler.animateUpdateOnceOffOverride = animate
	}

	public var projectedValue: Self
	{
		self
	}

	public func update()
	{
#if DEBUG
		if databaseReader == nil
		{
			os_log("‼️ No GRDB database passed to SwiftUI environment. Use the `.attachDatabase` modifier (in SceneDelegate or elsewhere). This will fail silently in release builds.", log: OSLog.default, type: .error)
		}
#endif
		handler.database = databaseReader
	}
}

internal class GRDBFetchHandler<FetchRequest: GRDBFetchRequest>: ObservableObject
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

	var animateUpdates: Bool = true
	var animateUpdateOnceOffOverride: Bool?

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

	var database: DatabaseReader?
	{
		didSet
		{
			if database !== oldValue, database != nil
			{
				setupPublisher()
			}
		}
	}

	private var subscription: AnyCancellable?
	private var publisher: AnyPublisher<FetchRequest.Result, Never>?

	init(db: DatabaseReader?, request: FetchRequest, animateUpdates: Bool)
	{
		database = db
		result = request.defaultResult
		fetchRequest = request
		self.animateUpdates = animateUpdates
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
			self?.handleUpdate(result)
		}
	}

	func handleUpdate(_ result: FetchRequest.Result)
	{
		let updates = {
			self.result = result
			self.isLoadingInitialResult = false
		}
		if animateUpdateOnceOffOverride ?? animateUpdates
		{
			withAnimation {
				updates()
			}
		}
		else
		{
			updates()
		}

		animateUpdateOnceOffOverride = nil
	}
}
