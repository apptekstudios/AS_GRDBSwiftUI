import Foundation
import Combine
import GRDB
import GRDBCombine

@_exported import class GRDB.Database

public protocol GRDBFetchRequest {
	associatedtype Result
	var defaultResult: Result { get }
	func request(db: GRDB.Database) throws -> Result
}

public struct GRDBFetchRequestSimple<FetchResult> {
	public typealias RequestClosure = ( (_ database: Database) throws -> FetchResult)
	
	var requestClosure: RequestClosure
	var defaultResult: FetchResult
	
	/// Database request returning an non-optional result, with a default value if no record/s found
	public init(defaultResult: FetchResult, _ request: @escaping RequestClosure) {
		self.requestClosure = request
		self.defaultResult = defaultResult
	}
	
	/// Database request returning an array of Records
	public init<DataElement>(_ request: @escaping RequestClosure) where FetchResult == [DataElement] {
		self.requestClosure = request
		self.defaultResult = []
	}
	/// Database request returning an optional Record
	public init<DataElement>(_ request: @escaping RequestClosure) where FetchResult == Optional<DataElement> {
		self.requestClosure = request
		self.defaultResult = nil
	}
}

public struct PlaceholderFetchRequest<FetchResult>: GRDBFetchRequest {
	public var defaultResult: FetchResult
	public func request(db: GRDB.Database) throws -> FetchResult {
		return defaultResult
	}
}
