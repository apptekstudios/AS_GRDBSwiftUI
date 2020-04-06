import Foundation
import Combine
import GRDB
import GRDBCombine

public struct GRDBFetchRequest<Data, Config> {
	public typealias RequestClosureWithConfig = ( (_ database: Database, _ config: Config) throws -> Data)
	public typealias RequestClosure = ( (_ database: Database) throws -> Data)
	public var config: Config
	var requestClosure: RequestClosureWithConfig
	var defaultResult: Data
	
	/// Database request returning an non-optional result, with a default value if no record/s found
	public init(defaultResult: Data, config: Config, _ request: @escaping RequestClosureWithConfig) {
		self.config = config
		self.requestClosure = request
		self.defaultResult = defaultResult
	}
	
	/// Database request returning an array of Records
	public init<DataElement>(config: Config, _ request: @escaping RequestClosureWithConfig) where Data == [DataElement] {
		self.config = config
		self.requestClosure = request
		self.defaultResult = []
	}
	/// Database request returning an optional Record
	public init<DataElement>(config: Config, _ request: @escaping RequestClosureWithConfig) where Data == Optional<DataElement> {
		self.config = config
		self.requestClosure = request
		self.defaultResult = nil
	}
}

extension GRDBFetchRequest where Config == Void {
	/// Database request returning an non-optional result, with a default value if no record/s found
	public init(defaultResult: Data, _ request: @escaping RequestClosure) {
		self.init(defaultResult: defaultResult, config: (), { db, _ in try request(db) })
	}
	
	/// Database request returning an array of Records
	public init<DataElement>(_ request: @escaping RequestClosure) where Data == [DataElement] {
		self.init(config: (), { db, _ in try request(db) })
	}
	/// Database request returning an optional Record
	public init<DataElement>(_ request: @escaping RequestClosure) where Data == Optional<DataElement> {
		self.init(config: (), { db, _ in try request(db) })
	}
}

import SwiftUI
/// An observable object that observes a database request and updates its `result` value with any changes
public class DatabaseFetch<Database: DatabaseReader, Data, Config>: ObservableObject {
	/// The result of the request. This is updated automatically with any changes.
	public var result: Data {
		willSet {
			objectWillChange.send()
		}
	}
	
	public var request: GRDBFetchRequest<Data, Config> {
		didSet {
			setupPublisher()
		}
	}
	
	private var database: Database
	
	private var subscription: AnyCancellable?
	private var publisher: AnyPublisher<Data, Never>?
	
	public init(db: Database, request: GRDBFetchRequest<Data, Config>) {
		self.database = db
		self.result = request.defaultResult
		self.request = request
		setupPublisher()
	}
	
	func setupPublisher() {
		self.publisher = ValueObservation
			.tracking(value: { db in
				try self.request.requestClosure(db, self.request.config)
			})
			.publisher(in: database)
			.replaceError(with: request.defaultResult)
			.eraseToAnyPublisher()
		self.subscription = publisher?.sink { [weak self] result in
			self?.result = result
		}
	}
}

