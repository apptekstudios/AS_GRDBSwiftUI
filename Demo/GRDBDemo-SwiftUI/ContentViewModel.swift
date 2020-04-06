//
//  ContentViewModel.swift
//  GRDBDemo-SwiftUI
//
//  Created by Toby Brennan on 6/4/20.
//  Copyright © 2020 Github-ApptekStudios. All rights reserved.
//

import Foundation
import AS_GRDBSwiftUI

struct ContentViewModel {
	/// A Hall of Fame
	struct HallOfFame {
		/// Total number of players
		var playerCount: Int = 0
		
		/// The best ones
		var bestPlayers: [Player] = []
	}
	
	/// A publisher that tracks changes in the Hall of Fame
	static func hallOfFameRequest(maxPlayerCount: Int, sorting: Player.SortOrder) -> GRDBFetchRequest<HallOfFame, Player.SortOrder> {
		GRDBFetchRequest(defaultResult: HallOfFame(), config: sorting) { db, sortOrder -> HallOfFame in
			let playerCount = try Player.fetchCount(db)
			let bestPlayers = try Player
				.limit(maxPlayerCount)
				.order(sortOrder.order)
				.fetchAll(db)
			return HallOfFame(playerCount: playerCount, bestPlayers: bestPlayers)
		}
	}
}
