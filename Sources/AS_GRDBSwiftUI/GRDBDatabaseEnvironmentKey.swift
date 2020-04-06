/*
//Saving this for when SwiftUI allows us to access the environment more readily from custom propertyWrappers
import SwiftUI
import GRDB

struct EnvironmentKeyGRDBDatabase: EnvironmentKey
{
	static let defaultValue: DatabaseWriter? = nil
}

public extension EnvironmentValues
{
	var grdbDatabaseReadOnly: DatabaseReader?
	{
		self[EnvironmentKeyGRDBDatabase.self]
	}
	
	var grdbDatabase: DatabaseWriter?
	{
		get { self[EnvironmentKeyGRDBDatabase.self] }
		set { self[EnvironmentKeyGRDBDatabase.self] = newValue }
	}
}

public extension View {
	func attachDatabase(_ database: DatabaseWriter) -> some View {
		environment(\.grdbDatabase, database)
	}
}
*/
