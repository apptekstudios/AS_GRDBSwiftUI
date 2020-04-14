
import GRDB
@_exported import class GRDB.Database

public protocol GRDBWriteRequest
{
	associatedtype Result
	func defineWriteTransaction(db: GRDB.Database) throws -> Result
	
	func execute(inDB databaseWriter: DatabaseWriter) throws -> Result
}

public extension GRDBWriteRequest {
	func execute(inDB databaseWriter: DatabaseWriter) throws -> Result {
		try databaseWriter.write {
			try defineWriteTransaction(db: $0)
		}
	}
}
