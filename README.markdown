# Findex #

Findex is a simple collection of Rake tasks that will help you locate missing database indexes in your Rails app. It can also generate migrations and run them, as well as filter by specific column types, names, and tables.

**Please note** that Findex designed to find any potentially overlooked indexes. It is not a good practice to index every matching column it returns - that's way too many.

## Installation ##

Install Findex as a gem:

	$ gem install findex --source=http://gems.github.com

You may want to configure it as a gem in environment.rb instead, since you're going to need it in your Rakefile:

	config.gem 'findex', :source => 'http://gemcutter.org'

... then run:

	rake gems:install

In either case. open your Rails app's Rakefile and add the following line:

	require 'findex/tasks'

And it's installed. Bam.

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