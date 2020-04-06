// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import AS_GRDBSwiftUI
import GRDB
import SwiftUI

struct PlayerLeaderboardView: View
{
	@ObservedObject var databaseFetch = GRDBFetchHandler(db: AppDatabase.shared.db, request: HallOfFame.DatabaseRequest())

	var body: some View
	{
		NavigationView {
			VStack(spacing: 0) {
				list
				count
				toolbar
			}
			.navigationBarItems(trailing:
				Button(action: {
					self.databaseFetch.request.sortOrder.toggle()
					}) {
					Text("Sort: \(self.databaseFetch.request.sortOrder.displayLabel)")
				}
			)
			.navigationBarTitle(Text("Leaderboard"))
		}
	}

	var count: some View
	{
		Text("\(databaseFetch.result.playerCount) \(databaseFetch.result.playerCount == 1 ? "Player" : "Players") in total")
			.padding()
			.frame(maxWidth: .infinity)
			.background(Color(.secondarySystemBackground))
	}

	var list: some View
	{
		List {
			ForEach(databaseFetch.result.bestPlayers) {
				PlayerRow(player: $0)
			}
			.onDelete { indexSet in
				let toDelete = indexSet.map { self.databaseFetch.result.bestPlayers[$0] }

				do
				{
					// You should probably handle this in your data controller rather than in the view code
					try AppDatabase.shared.db.write { db in
						toDelete.forEach { player in
							do
							{
								try player.delete(db)
							}
							catch
							{
								// Catch errors here so that the forEach completes as expected
							}
						}
					}
				}
				catch
				{
					// Handle any errors if considered important
				}
			}
		}
	}

	var toolbar: some View
	{
		HStack {
			Button(
				action: { try? Players.deleteAll(AppDatabase.shared.db) },
				label: { Image(systemName: "trash") })
			Spacer()
			Button(
				action: { try? Players.refresh(AppDatabase.shared.db) },
				label: { Image(systemName: "arrow.clockwise") })
			Spacer()
			Button(
				action: { Players.stressTest(AppDatabase.shared.db) },
				label: { Text("💣") })
		}
		.padding()
	}
}

struct PlayerRow: View
{
	var player: Player

	var body: some View
	{
		NavigationLink(destination: PlayerEditingView(player: GRDBMutableRecord(database: AppDatabase.shared.db, value: player, autoSave: false))) {
			HStack {
				Text(player.name)
				Spacer()
				Text("\(player.score)")
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider
{
	static var previews: some View
	{
		PlayerLeaderboardView()
	}
}
