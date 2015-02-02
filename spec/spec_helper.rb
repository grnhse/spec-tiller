require 'bundler/setup'
Bundler.setup

require 'spec_tiller' # and any other gems you need

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|

  if ENV['CI_ENV'] == 'travis'
    config.add_formatter('progress')
    config.add_formatter(ProfileToFileFormatter)
  end
end