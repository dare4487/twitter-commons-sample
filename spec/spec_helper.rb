require 'rubygems'
require 'bundler/setup'

require File.expand_path(File.dirname(__FILE__) + '/../lib/ach_builder.rb')
Dir[File.expand_path(File.dirname(__FILE__) + '/support/**/*.rb')].each {|f| require f}

RSpec.configure do |config|
  # some (optional) config here
end