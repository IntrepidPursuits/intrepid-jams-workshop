# Intrepid jam workshop

# Rails API Workshop - May 6, 2016

## Pre-workshop setup

* Install the following, either via Thoughtbot's [laptop script](https://github.com/thoughtbot/laptop) which will install all of these, or individually:
  - Homebrew
  - A Ruby version manager (we recommend [rbenv](https://github.com/rbenv/rbenv)) and Ruby 2.3.0.
  - Bundler, Rails, and Suspenders gems
    ```
    $ gem install bundler
    $ gem install rails
    $ gem install suspenders
    ```

    - Postgres - can use Homebrew (https://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/) or the Postgres app (http://postgresapp.com/)

* Create a Heroku account, download the Heroku toolbelt (not necessary if you used the laptop script), and login (see instructions here https://toolbelt.heroku.com/).  This gives you the Heroku CLI which has some useful commands for deploying, interacting with your database, and running rake tasks.

You'll also want a text editor of some kind (Atom, Sublime, Vim) or IDE (RubyMine).

## A few things to know about Rails

* Naming conventions - casing, pluraliztion, filenames & paths matter
* Other???

## Building an API

### Overview

We're going to build an app that keeps track of Intrepid Jam games and lets us record new ones.  We'll have the following endpoints:

```
GET /games # returns a list of all games
POST /games # create a new game
```

Our data model will look like this (note that I'm leaving off `created_at`, and `updated_at` properties on each table, which Rails gives us for free; it also gives us `id` for free but I'm listing it here so we can see how the foreign and primary keys link up):

```
Game
-------
id

Team
------
id
game_id
score
name
player_names
```

### Step 1. Generate a new Rails app

There are a few different options for generating a new Rails app:

```
$ rails new <app_name>
$ rails-api new <app_name>
$ suspenders <app_name>
```

`rails new` is the standard Rails command for generating a new app.
`rails-api new` generates a Rails app without any of the asset pipeline components that are used for a frontend web Rails app.
`suspenders` is basically `rails new` plus a lot of the common libraries we use.  It comes from the [suspenders](https://github.com/thoughtbot/suspenders) gem.

### Commands to run

```
$ suspenders intrepid_jams
$ cd intrepid_jams/
$ bundle
$ rake db:create && rake db:migrate
$ git init && git add . && git commit -am "Initial commit - new Suspenders app"
```

### Review structure of a Rails app

```
app/
- models/
- controllers/

db/
- migrate/
- schema.rb

config/
- routes.rb
```  

### Step 2. Add our models

Rails provides some generators for creating different components of an app (e.g. a model, a controller, etc.).  I don't use most of them, but some are helpful, for example for generating models.

```
$ rails g model game
      invoke  active_record
      create    db/migrate/20160429184249_create_games.rb
      create    app/models/game.rb
      invoke    rspec
      create      spec/models/game_spec.rb
      invoke      factory_girl
      create        spec/factories/games.rb
```

This creates a bunch of files for you, namely: the model; a migration, which, when run, will create a `games` database table; and some stuff for testing which we won't worry about now.  [Take a look at the model & the migration & discuss.]

Run `rake db:migrate` to apply the changes in the migration to the database.  You'll see the `db/schema.rb` file has changed to reflect these changes.

```
$ rake db:migrate
```

Add the team model, which has additional attributes beyond the basic `id` and timestamps:

```
$ rails g model team name:string player_names:string score:integer game:references
$ rake db:migrate
```

[Discuss migration & model, touch on associations.]

Normally I'd consider adding validations at this point -- we might want to ensure, for example, that every team has a name and a `game_id`, but for now we'll leave as is for the sake of time.

### Step 3. Add a `GET /games` endpoint

There are two main components we'll need to add to create a `GET /games` endpoint:
- A `route` in `config/routes.rb`.  Tells Rails what to do when it gets a request to `GET /games` (i.e. which controller action to call)
- A controller and a controller action to handle requests to that route.
  * A controller action is really just a method or function -- I don't know why we call them actions
  * There are Rails conventions around controller action names - discuss.  (index, show, create, update, delete)

Add a route:

```ruby
Rails.application.routes.draw do
  resources :games, only: :index
end
```

You can see all the routes in your app by running `rake routes`, along with the controller & action they map to:

```
$  rake routes
Prefix Verb URI Pattern      Controller#Action
 games GET  /games(.:format) games#index
  page GET  /pages/*id       high_voltage/pages#show
```

[Talk about the `resources` method, vs. `get '/games' => 'games#index'` for example.]

Let's start up our app and go to that endpoint in our browser.  You can run `rails server` or `rails s` and then go to http://localhost:3000/games in your browser, and you'll see a nice little error message telling us we don't have a controller.

```
$ rails server
```

Let's add our controller, with an index action:

```
$ touch app/controllers/games_controller.rb
```

```ruby
class GamesController < ApplicationController
  def index
  end
end
```

If we go to that url now, we'll see a different error -- it tells us a template is missing.  That's because what Rails does here is that it assumes you want to render HTML from a template located at `app/views/games/index.html.erb`, and there's nothing there.

We can shut it up by explicitly telling it what to render.  Let's render some empty JSON:

```ruby
class GamesController < ApplicationController
  def index
    render json: []
  end
end
```

And now we should see an empty array in our browser.

But we don't want to show an empty array, we want to show all the `Games` in our database. The parent class of our `Game` model, `ActiveRecord::Base`, defines a whole bunch of query methods, including `.all`, which we can call on the `Game` class to fetch all games:

```ruby
class GamesController < ApplicationController
  def index
    games = Game.all

    render json: games
  end
end
```

Obviously we don't have any games in our DB, so let's change that.

There are a couple of ways I can put data in my database:
- I can run `rails console` and create some fake data in there.
- I can add some commands to create fake data in `db/seeds.rb` and run `rake db:seed`.  Normally I would only do this for data that I needed to seed in the production DB but for now I'll do that anyway.

```ruby
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
```

Now if we go to the browser we can see some games.  You'll notice, though, that we're only seeing the properties that live on the `Game` model -- we're not seeing anything useful about the games' associated teams.  That's because when we say `render json: games`, Rails is under the hood looping over each game and calling a `to_json` method on it, which creates a JSON respresentation of the object including all of its properties.

Obviously for this to be useful we probably want to show information about teams also.  There are a couple of ways we could do this -- we could simply override the `to_json` method, or pass some options to it to tailor what we show.  But we usually go with a serialization library called `active_model_serializers`.

Let's add that so we can tailor our JSON response.

First we need to add a `has_many :teams` association to `Game` (I should probably move this earlier when we're talking about associations).

```ruby
class Game < ActiveRecord::Base
  has_many :teams
end
```

Generate a serializer:

```
$ rails g serializer game
      create  app/serializers/game_serializer.rb
```

Modify the serializer to include teams:

```ruby
class GameSerializer < ActiveModel::Serializer
  attributes :id

  has_many :teams
end
```

Now if we go back to the browser, we'll see a couple things are different (we'll need to restart the server b/c we changed the Gemfile):
- All the games are nested under a `games` key.
- Timestamps are gone (only attributes specified in the serializer are displayed)
- Teams are embedded under a `teams` key in each `game`
  * This is the AM::S default
  * If we wanted to sideload these instead, you could add `embed :ids` to your `GameSerializer`. Try that and see what happens.

## Deploying to Heroku

- Add the rails 12 factor gem

- In the Heroku dashboard, create a new app (can also use `heroku create` command -- I don't b/c I have multiple Heroku accounts and it can get screwy)
- Set environment variables, either via the Heroku dashboard or `heroku config:set <VAR_NAME>=<var>`
- Find the SSH URL and add it as a remote:

```
$ git remote add <remote_name> git@heroku.com:<heroku_app_name>.git
```

- Now to deploy:

```
$ git push <remote_name> master
$ heroku run rake db:migrate
$ heroku run rake db:seed
```

Now you should be able to navigate to `<heroku_app_name>.herokuapp.com/games` (can run `heroku open` to open the root URL in the browser)

## Other helpful tidbits

- View heroku logs: `heroku logs --tail`
- `binding.pry`

# Next Exercises

1. Add a `Player` model

A `Team` should have many `Player`s, and should no longer have a `player_names` attribute.

A `Player` should have a first name, last name, and jersey number.

2. Change the association between `Game` and `Team`

Right now, if a `Team` plays multiple games, they'll show up twice in our database.  This isn't optimal because duplicated data provides more room for error.

Let's change the data model so that `Team`s can play in multiple games.  Our model should look like this:

```
Game
-------
id

CompetingTeam
--------------
id
game_id
team_id
score

Team
------
id
name

Player
-------
id
first_name
last_name
jersey_number
```

Update the `GET /games` endpoint to return information on the competing teams.

```json
{
  "games": [
    {
      "id": 1,
      "competing_teams": [
        {
          "id": 3,
          "name": "Rams",
          "score": 90
        },
        {
          "id": 7,
          "name": "Lakers",
          "score": 72
        }
      ]
    }
  ]
}
```

3. Add a `GET /teams` endpoint

This endpoint should return a list of teams with each team's ID and name.

```json
{
  "teams": [
    {
      "id": 3,
      "name": "Rams"
    },
    {
      "id": 7,
      "name": "Lakers"
    }
  ]
}
```

4. Add a `GET /teams/:id` endpoint

This endpoint should return all the information we have about a `Team`, including its name, a list of players, and a list of the games they've played.

```json
{
  "team": {
    "id": 3,
    "name": "Rams",
    "players": [
      {
        "id": 17,
        "first_name": "David",
        "last_name": "Rodriguez",
        "jersey_number": 25
      }
    ],
    "games": [
      {
        "id": 1,
        "score": 90,
        "opposing_team_name": "Lakers",
        "opposing_team_score": 72
      }
    ]
  }
}
```

# Basic Suspenders stuff

## Getting Started

After you have cloned this repo, run this setup script to set up your machine
with the necessary dependencies to run and test this app:

    % ./bin/setup

It assumes you have a machine equipped with Ruby, Postgres, etc. If not, set up
your machine with [this script].

[this script]: https://github.com/thoughtbot/laptop

After setting up, you can run the application using [Heroku Local]:

    % heroku local

[Heroku Local]: https://devcenter.heroku.com/articles/heroku-local

## Guidelines

Use the following guides for getting things done, programming well, and
programming in style.

* [Protocol](http://github.com/thoughtbot/guides/blob/master/protocol)
* [Best Practices](http://github.com/thoughtbot/guides/blob/master/best-practices)
* [Style](http://github.com/thoughtbot/guides/blob/master/style)
