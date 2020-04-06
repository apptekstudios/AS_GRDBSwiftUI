// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import GRDB

// A plain Player struct
struct Player
{
	// Use Int64 for auto-incremented database ids
	var id: Int64?
	var name: String
	var score: Int
}

// Support for UIViewController (difference(from:).inferringMoves())
extension Player: Hashable {}

// Support for SwiftUI (List)
extension Player: Identifiable {}

// MARK: - Persistence

// Turn Player into a Codable Record.
// See https://github.com/groue/GRDB.swift/blob/master/README.md#records
extension Player: Codable, FetchableRecord, MutablePersistableRecord
{
	// Define database columns from CodingKeys
	fileprivate enum Columns
	{
		static let id = Column(CodingKeys.id)
		static let name = Column(CodingKeys.name)
		static let score = Column(CodingKeys.score)
	}

	// Update a player id after it has been inserted in the database.
	mutating func didInsert(with rowID: Int64, for _: String?)
	{
		id = rowID
	}
}

extension Player
{
	enum SortOrder
	{
		case name
		case score

		mutating func toggle()
		{
			switch self
			{
			case .name:
				self = .score
			case .score:
				self = .name
			}
		}

		var order: [SQLOrderingTerm]
		{
			switch self
			{
			case .name:
				return [Columns.name]
			case .score:
				return [Columns.score.desc, Columns.name]
			}
		}

		var displayLabel: String
		{
			switch self
			{
			case .name:
				return "Name"
			case .score:
				return "Score"
			}
		}
	}
}
