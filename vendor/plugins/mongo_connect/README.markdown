MongoConnect
=================
TRABAJO EN PROCESO

Connect to mongodb orms via config files, cloud DNA, etc via *ONE* line of code

Tired of checking corner cases, writing error messages,
loading json and yaml and running erb replacements and disabling on development
and connecting to a slave and master on the clouds? Meh.

Connect with config file(s) per environment, instance DNA, options, whatever

Automatically connects to installed orms:
Mongo (Driver), MongoMapper, Mongorecord


Example
=======
Connect mongomapper to localhost using default database of appname_development
    MongoConfigurator.setup( :host => 'localhost', :orms => :mongo_mapper )

Connect to port 21345 with the server named 'mongodb' in engineyard solo
    MongoConfigurator.setup( :port => '21345', :dna => {:enable => true, :instance_name => 'mongodb'} )

Read the rest of the configuration settings from config/app.yml and config/production.yml
    MongoConfigurator.setup( :config_file => ['config/app.yml', 'config/:env.yml'])

    MongoConfigurator.connected?
    MongoConfigurator.reconnect


Copyright (c) 2009 Blythe Dunham, released under the MIT license
