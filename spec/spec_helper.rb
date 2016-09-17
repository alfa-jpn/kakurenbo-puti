require 'rubygems'
require 'bundler/setup'
require 'spec_helpers/active_record_model'
require 'coveralls'
require 'kakurenbo-puti'

RSpec.configure do |config|
  config.color = true
  config.mock_framework = :rspec
  config.before :all do
    ActiveRecord::Base.logger = Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN }
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
  end
end

Coveralls.wear!
