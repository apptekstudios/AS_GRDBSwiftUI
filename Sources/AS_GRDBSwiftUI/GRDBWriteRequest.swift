// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import GRDB
@_exported import class GRDB.Database

public protocol GRDBWriteRequest
{
	associatedtype Result
	func onWrite(db: GRDB.Database) throws -> Result

	func executeRequest(inDB databaseWriter: DatabaseWriter) throws -> Result
}

public extension GRDBWriteRequest
{
	func executeRequest(inDB databaseWriter: DatabaseWriter) throws -> Result {
		try databaseWriter.write {
			try onWrite(db: $0)
		}
	}
}
