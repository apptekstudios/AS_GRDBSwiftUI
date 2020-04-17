// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import AS_GRDBSwiftUI
import Foundation

/// A Hall of Fame
struct HallOfFame
{
	/// Total number of players
	var playerCount: Int = 0

	/// The best ones
	var bestPlayers: [Player] = []

	struct DatabaseRequest: GRDBFetchRequest
	{
		var maxPlayerCount = 100
		var sortOrder: Player.SortOrder = .score

		var defaultResult = HallOfFame()
		func onRead(db: Database) throws -> HallOfFame {
			let playerCount = try Player.fetchCount(db)
			let bestPlayers = try Player
				.limit(maxPlayerCount)
				.order(sortOrder.order)
				.fetchAll(db)
			return HallOfFame(playerCount: playerCount, bestPlayers: bestPlayers)
		}
	}
}
