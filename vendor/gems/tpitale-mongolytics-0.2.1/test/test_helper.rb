$:.reject! { |e| e.include? 'TextMate' }

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'mocha'
require 'mongomapper'

require File.dirname(__FILE__) + '/../lib/mongolytics'

# connect to mongodb?
