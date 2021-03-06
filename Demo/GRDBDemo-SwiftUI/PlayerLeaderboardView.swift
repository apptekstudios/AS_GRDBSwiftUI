// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import AS_GRDBSwiftUI
import GRDB
import SwiftUI

struct PlayerLeaderboardView: View
{
	@GRDBFetch(request: HallOfFame.DatabaseRequest())
	var databaseFetchResult

	// Used for the toolbar buttons (not required for the Fetch above to work)
	@Environment(\.grdbDatabaseWriter) var database

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
					self.$databaseFetchResult.request.sortOrder.toggle()
					}) {
					Text("Sort: \(self.$databaseFetchResult.request.sortOrder.displayLabel)")
				}
			)
			.navigationBarTitle(Text("Leaderboard"))
		}
	}

	var count: some View
	{
		Text("\(databaseFetchResult.playerCount) \(databaseFetchResult.playerCount == 1 ? "Player" : "Players") in total")
			.padding()
			.frame(maxWidth: .infinity)
			.background(Color(.secondarySystemBackground))
	}

	var list: some View
	{
		List {
			ForEach(databaseFetchResult.bestPlayers) {
				PlayerRow(player: $0)
			}
			.onDelete { indexSet in
				let toDelete = indexSet.map { self.databaseFetchResult.bestPlayers[$0] }

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
				action: {
					self.database.map {
						try? Player.DeleteAllPlayersRequest().executeRequest(inDB: $0)
					}
				},
				label: { Image(systemName: "trash") })
			Spacer()
			Button(
				action: {
					self.database.map {
						try? Player.RefreshPlayersRequest().executeRequest(inDB: $0)
					}
				},
				label: { Image(systemName: "arrow.clockwise") })
			Spacer()
			Button(
				action: {
					self.database.map {
						Player.stressTest($0)
					}
				},
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
		NavigationLink(destination: PlayerEditingView(player: GRDBPersistable(player, autoSave: false))) {
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
