# SpecTiller

  This gem will parse the output of calling "rspec --perform", then will redistribute
  the spec files evenly, based on file run time, across all builds established
  in the travis.yml file.

## Installation

  Add this line to your application's Gemfile:

      gem 'spec_distributor'

  And then execute:

      $ bundle

  Or install it yourself as:

      $ gem install spec_distributor

  Create the following two files in the .git/hooks/ directory of your app:
      'pre-commit'
      'post-merge'
      (More information on git hooks: http://git-scm.com/book/en/Customizing-Git-Git-Hooks)

  In each of those two files, add the following rake task:
    rake spec_distributor:sync_file_list

  In your travis.yml file:
    Create a top-level variable 'num_builds' and set it to the number of builds you want the spec files distributed over

    Make sure that the base of your script is as follows:
      bundle exec rspec $TEST_SUITE

<!-- ## Usage

  TODO: Write usage instructions here -->

## Contributing

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Add some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request