import Combine
import GRDB
import GRDBCombine
import Dispatch

/// Players is responsible for high-level operations on the players database.
struct Players {
    private let database: AppDatabase
    
    init(database: AppDatabase) {
        self.database = database
    }
    
    // MARK: - Modify Players
    
    func deleteAll() throws {
		try database.db.write { db in
            _ = try Player.deleteAll(db)
        }
    }
    
    func refresh() throws {
		try database.db.write { db in
            if try Player.fetchCount(db) == 0 {
                // Insert new random players
                for _ in 0..<8 {
                    var player = Player(id: nil, name: Players.randomName(), score: Players.randomScore())
                    try player.insert(db)
                }
            } else {
                // Insert a player
                if Bool.random() {
                    var player = Player(id: nil, name: Players.randomName(), score: Players.randomScore())
                    try player.insert(db)
                }
                // Delete a random player
                if Bool.random() {
                    try Player.order(sql: "RANDOM()").limit(1).deleteAll(db)
                }
                // Update some players
                for var player in try Player.fetchAll(db) where Bool.random() {
                    player.score = Players.randomScore()
                    try player.update(db)
                }
            }
        }
    }
    
    func stressTest() {
        for _ in 0..<50 {
            DispatchQueue.global().async {
                try? self.refresh()
            }
        }
    }
	
	private static let names = [
		"Arthur", "Anita", "Barbara", "Bernard", "Clément", "Chiara", "David",
		"Dean", "Éric", "Elena", "Fatima", "Frederik", "Gilbert", "Georgette",
		"Henriette", "Hassan", "Ignacio", "Irene", "Julie", "Jack", "Karl",
		"Kristel", "Louis", "Liz", "Masashi", "Mary", "Noam", "Nolwenn",
		"Ophelie", "Oleg", "Pascal", "Patricia", "Quentin", "Quinn", "Raoul",
		"Rachel", "Stephan", "Susie", "Tristan", "Tatiana", "Ursule", "Urbain",
		"Victor", "Violette", "Wilfried", "Wilhelmina", "Yvon", "Yann",
		"Zazie", "Zoé"]
	
	static func randomName() -> String {
		names.randomElement()!
	}
	
	static func randomScore() -> Int {
		10 * Int.random(in: 0...100)
	}
}

