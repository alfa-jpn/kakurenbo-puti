require 'rubygems'
require 'bundler/setup'
require 'supports/active_record_model'
require 'kakurenbo_puti'

RSpec.configure do |config|
  config.color = true
  config.mock_framework = :rspec
  config.before :all do
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
  end
end
