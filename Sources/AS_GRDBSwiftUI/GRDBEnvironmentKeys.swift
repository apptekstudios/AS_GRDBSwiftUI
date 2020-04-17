// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import GRDB
import SwiftUI

struct EnvironmentKeyGRDBDatabase: EnvironmentKey
{
	static let defaultValue: DatabaseWriter? = nil
}

public extension EnvironmentValues
{
	var grdbDatabaseReader: DatabaseReader?
	{
		self[EnvironmentKeyGRDBDatabase.self]
	}

	var grdbDatabaseWriter: DatabaseWriter?
	{
		get { self[EnvironmentKeyGRDBDatabase.self] }
		set { self[EnvironmentKeyGRDBDatabase.self] = newValue }
	}
}

public extension View
{
	func attachDatabase(_ database: DatabaseWriter) -> some View
	{
		environment(\.grdbDatabaseWriter, database)
	}
}
