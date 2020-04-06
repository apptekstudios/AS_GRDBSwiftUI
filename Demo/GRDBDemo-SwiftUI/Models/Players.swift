// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Combine
import Dispatch
import GRDB
import GRDBCombine

struct Players
{
	static func deleteAll(_ db: DatabaseWriter) throws
	{
		try db.write { db in
			_ = try Player.deleteAll(db)
		}
	}

	static func refresh(_ db: DatabaseWriter) throws
	{
		try db.write { db in
			if try Player.fetchCount(db) == 0
			{
				// Insert new random players
				for _ in 0 ..< 8
				{
					var player = Player(id: nil, name: Players.randomName(), score: Players.randomScore())
					try player.insert(db)
				}
			}
			else
			{
				// Insert a player
				if Bool.random()
				{
					var player = Player(id: nil, name: Players.randomName(), score: Players.randomScore())
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
					player.score = Players.randomScore()
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
				try? self.refresh(db)
			}
		}
	}

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
