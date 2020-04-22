// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import GRDB
@_exported import class GRDB.Database

public protocol GRDBWriteRequest
{
	associatedtype Value
	associatedtype Result
	func onWrite(db: GRDB.Database, value: Value) throws -> Result

	@discardableResult
	func executeRequest(inDB databaseWriter: DatabaseWriter, withValue value: Value) throws -> Result
	func executeRequest(inDB databaseWriter: DatabaseWriter, withMutableValue value: inout Value) throws -> Result
}

public extension GRDBWriteRequest
{
	func executeRequest(inDB databaseWriter: DatabaseWriter, withValue value: Value) throws -> Result {
		try databaseWriter.write {
			try onWrite(db: $0, value: value)
		}
	}

	// This allows for us to call a write request without knowing whether it needs a mutable value or not
	func executeRequest(inDB databaseWriter: DatabaseWriter, withMutableValue value: inout Value) throws -> Result {
		try executeRequest(inDB: databaseWriter, withValue: value)
	}
}

public extension GRDBWriteRequest where Result == Value
{
	func executeRequest(inDB databaseWriter: DatabaseWriter, withMutableValue value: inout Value) throws -> Value {
		let updated = try executeRequest(inDB: databaseWriter, withValue: value)
		value = updated
		return value
	}
}

public extension GRDBWriteRequest where Value == Void
{
	func executeRequest(inDB databaseWriter: DatabaseWriter) throws -> Result {
		try executeRequest(inDB: databaseWriter, withValue: ())
	}
}
