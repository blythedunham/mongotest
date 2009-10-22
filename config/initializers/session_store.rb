# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mongotest_session',
  :secret      => 'd8eed79f10cf077971d6054f8a068a86f8f40a2c2042c0167781e4193c03044d59603f46f3adf5ebef7fff118f5039d23b5cde6bfca196a888a7053108172654'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
