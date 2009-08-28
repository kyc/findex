# rake:db:indexes #

rake:db:indexes is a simple Rake task plugin that will help you locate missing database indexes. It can also generate migrations and run them, as well as filter by specific column types, names, and tables.

## Installation ##

For now, install it as a Rails plugins:

	ruby script/plugin install git://github.com/flipsasser/rake-db-indexes.git

I will add a Gem sooner or later.

## Find Missing Indexes ##

First, get some instructions:

	$ rake db:indexes:help
	
	rake db:indexes will generate a list of indexes your application's database may or may not need.
	
	To see a list of all indexes it thinks you need, just use rake db:indexes

	You can add migration=true to generate a migration file
	or perform=true to perform the indexing immediately:
		`rake db:indexes migration=true`
	
	You can also target specific column types, like so:
		`rake db:indexes:boolean`
		`rake db:indexes:datetime`
		`rake db:indexes:geo`
		`rake db:indexes:primary`
		`rake db:indexes:relationships`

	You can also filter by column names and types, or by whole tables:
		`rake db:indexes:names names=type,state`
		`rake db:indexes:types types=integer,decimal`
		`rake db:indexes tables=users,posts`

Read the instructions above and start finding missing indexes! Thanks to Matt Janowski for the inspiration (http://robots.thoughtbot.com/post/163627511/a-grand-piano-for-your-violin) and Thoughtbot / Jon Yurek for the core of the indexes detection code!

Copyright (c) 2009 Flip Sasser, released under the MIT license.