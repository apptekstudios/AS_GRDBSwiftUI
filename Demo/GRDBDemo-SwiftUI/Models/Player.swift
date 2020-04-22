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

import AS_GRDBSwiftUI
import Foundation

extension Player
{
	struct DeleteRequest: GRDBWriteRequest
	{
		func onWrite(db: Database, value: Player) throws
		{
			try value.delete(db)
		}
	}

	struct DeleteAllPlayersRequest: GRDBWriteRequest
	{
		func onWrite(db: Database, value: Void) throws
		{
			try Player.deleteAll(db)
		}
	}

	struct RefreshPlayersRequest: GRDBWriteRequest
	{
		func onWrite(db: Database, value: Void) throws
		{
			if try Player.fetchCount(db) == 0
			{
				// Insert new random players
				for _ in 0 ..< 8
				{
					var player = Player.random()
					try player.insert(db)
				}
			}
			else
			{
				// Insert a player
				if Bool.random()
				{
					var player = Player.random()
					try player.insert(db)
				}
				// Delete a random player
				if Bool.random()
				{
					try Player.order(sql: "RANDOM()").limit(1).deleteAll(db)
				}
				// Update some players
				for var player in try Player.fetchAll(db) where Bool.random()
				{
					player.score = Player.Random.randomScore()
					try player.update(db)
				}
			}
		}
	}

	static func stressTest(_ db: DatabaseWriter)
	{
		for _ in 0 ..< 50
		{
			DispatchQueue.global().async {
				try? RefreshPlayersRequest().executeRequest(inDB: db)
			}
		}
	}
}

extension Player
{
	struct Random
	{
		private static let names = ["Arthur", "Anita", "Barbara", "Bernard", "Clément", "Chiara", "David",
									"Dean", "Éric", "Elena", "Fatima", "Frederik", "Gilbert", "Georgette",
									"Henriette", "Hassan", "Ignacio", "Irene", "Julie", "Jack", "Karl",
									"Kristel", "Louis", "Liz", "Masashi", "Mary", "Noam", "Nolwenn",
									"Ophelie", "Oleg", "Pascal", "Patricia", "Quentin", "Quinn", "Raoul",
									"Rachel", "Stephan", "Susie", "Tristan", "Tatiana", "Ursule", "Urbain",
									"Victor", "Violette", "Wilfried", "Wilhelmina", "Yvon", "Yann",
									"Zazie", "Zoé"]
		static func randomName() -> String
		{
			names.randomElement()!
		}

		static func randomScore() -> Int
		{
			10 * Int.random(in: 0 ... 100)
		}
	}

	static func random() -> Player
	{
		Player(id: nil, name: Random.randomName(), score: Random.randomScore())
	}
}
