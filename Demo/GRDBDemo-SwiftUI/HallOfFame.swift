//
//  ContentViewModel.swift
//  GRDBDemo-SwiftUI
//
//  Created by Toby Brennan on 6/4/20.
//  Copyright © 2020 Github-ApptekStudios. All rights reserved.
//

import Foundation
import AS_GRDBSwiftUI

/// A Hall of Fame
struct HallOfFame {
	/// Total number of players
	var playerCount: Int = 0
	
	/// The best ones
	var bestPlayers: [Player] = []
	
	struct DatabaseRequest: GRDBFetchRequest {
		var maxPlayerCount = 100
		var sortOrder: Player.SortOrder = .score
		
		var defaultResult = HallOfFame()
		func request(db: Database) throws -> HallOfFame {
			let playerCount = try Player.fetchCount(db)
			let bestPlayers = try Player
				.limit(maxPlayerCount)
				.order(sortOrder.order)
				.fetchAll(db)
			return HallOfFame(playerCount: playerCount, bestPlayers: bestPlayers)
		}
	}
}
