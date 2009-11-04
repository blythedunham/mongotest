# Stalkerazzi
#

require 'stalkerazzi/tracker'
require 'stalkerazzi/core_ext/controller'

#Dir.glob( File.join( File.dirname(__FILE__), 'stalkerazzi', '*.rb' ) ) { |f| puts f; require f }
Dir.glob( File.join( File.dirname(__FILE__), 'stalkerazzi', '**', '*.rb' ) ) { |f| require f }


def preload_gem( gem_name, required_file = nil )
  gem gem_name
  require required_file if required_file
rescue LoadError => e
end

preload_gem 'mongo', 'mongo'
preload_gem 'mongo_mapper', 'mongo_mapper'
preload_gem 'mongo_record', 'mongo_record'