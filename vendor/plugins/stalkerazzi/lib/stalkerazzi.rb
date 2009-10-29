# Stalkerazzi
# 
Dir.glob( File.join( File.dirname(__FILE__), 'stalkerazzi', '*.rb' ) ) { |f| require f }
Dir.glob( File.join( File.dirname(__FILE__), 'stalkerazzi', 'trackers', '*.rb' ) ) { |f| require f }
