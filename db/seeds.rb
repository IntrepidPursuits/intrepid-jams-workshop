games = [{ teams: [{ name: 'Bulls', player_names: 'Danny, Benn', score: 812 },
                   { name: 'Spurs', player_names: 'Logan, Ben', score: 56 }] },
         { teams: [{ name: 'Celtics', player_names: 'Brian, Paul', score: 34 },
                   { name: 'Spurs', player_names: 'Rachel, Helen', score: 10000 }] },
         { teams: [{ name: 'Lakers', player_names: 'Nick, Liz', score: 92 },
                   { name: 'Knicks', player_names: 'Bryant, Dave', score: 786 }] }]

puts 'Seeding 3 games...'

games.each do |game_attrs|
  game = Game.create
  game_attrs[:teams].each do |team_attrs|
    team = Team.new(team_attrs)
    team.game = game
    team.save
  end
end

puts 'Done.'
