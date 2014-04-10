INSTRUCTIONS
1. Create the following two files in the .git/hooks/ directory of your app:
  a. pre-commit
  b. post-merge
2. In each of those two files, add the following lines:
  #!/bin/sh
  ruby script/spec_files/pre_commit_spec_files_check.rb # get correct directory
  git add .travis.yml
3. In your travis.yml file, you create a top-level variable 'num_builds' and set it to the number of builds you want the spec files distributed over
4. Make sure that the base of your script is as follows:
  a. bundle exec rspec $TEST_SUITE







# SpecDistributor

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'spec_distributor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spec_distributor

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
