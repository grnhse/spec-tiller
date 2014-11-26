# SpecTiller

## Description
This gem will parse the output of calling "rspec --perform", and then will redistribute the spec files evenly, based on file run time, across all builds established in the travis.yml file in order to optimize your test suite's run time. As of now, this gem is only compatible with Travis CI and their build matrix setup. For more information on this setup, check [here](http://docs.travis-ci.com/user/build-configuration/#The-Build-Matrix).

## Installation

Add this line to your application's ``Gemfile`` in **both** *development* and *test* groups:  

    group :development, :test do  
      gem 'spec_tiller'  
    end

And then execute:  

    $ bundle

## Set Up

#### Git Hooks  
In order to make sure that the travis file remains up to date with any newly added or removed spec files, you'll have to include a rake task in your pre-commit and post-merge git hooks. Create two files in .git/hooks/ --> ``pre-commit`` and ``post-merge`` (no file extension). **Please make sure that these files are executable** (more information on [git hooks](http://git-scm.com/book/en/Customizing-Git-Git-Hooks)). In each of those two files, add the following rake task:  

    #!/bin/sh  
    rake spec_tiller:sync

Upon setting this up, any time you commit or merge, you'll notice the following output:  

    Syncing list of spec files...  
    Removed: [spec/file/removed_spec.rb]  
    Added:   [spec/file/added_spec.rb, spec/file/another_added_spec.rb]

####.travis.yml
In your ``.travis.yml`` file, create a top-level variable **num_builds** and set it to the number of builds you want the spec files distributed over (default value is 5 builds). You must also make sure that the base of your script is as follows:

    bundle exec rspec $TEST_SUITE

*$TEST_SUITE* represents an environment variable. For the purpose of this gem, a list of space-separated spec files will be assigned to that variable. So, lets say that in ``.travis.yml``, *TEST_SUITE="spec/path/file_one_spec.rb spec/path/file_two_spec.rb spec/path/file_three_spec.rb"*, then the script above will execute as follows:  

    bundle exec rspec spec/path/file_one_spec.rb spec/path/file_two_spec.rb spec/path/file_three_spec.rb

Here is an example of what a ``.travis.yml`` file may look like after all is said and done.:  

    language: ruby
    rvm:
      - 1.9.3
    branches:
      only:
      - develop
      - master
      - /^release\/.*$/
      - /^hotfix\/.*$/
      - /^feature\/testing-.+$/
    cache: bundler
    before_install:
      - export DISPLAY=:99.0
      - sh -e /etc/init.d/xvfb start
    before_script:
      - psql -c 'create database test;' -U postgres
      - RAILS_ENV=test bundle exec rake --trace db:test:load db:seed
    script:
      - bundle exec rspec $TEST_SUITE --tag ~local_only
    env:
      global:
      - SOME_OTHER_ENV_VAR="hello world"
      - IGNORE_SPECS="spec/path/file_thirteen_spec.rb spec/path/file_fourteen_spec.rb"
      matrix:
      - TEST_SUITE="spec/path/file_one_spec.rb spec/path/file_two_spec.rb spec/path/file_three_spec.rb"
      - TEST_SUITE="spec/path/file_four_spec.rb"
      - TEST_SUITE="spec/path/file_five_spec.rb spec/path/file_six_spec.rb"
      - TEST_SUITE="spec/path/file_seven_spec.rb spec/path/file_eight_spec.rb spec/path/file_nine_spec.rb spec/path/file_ten_spec.rb"
      - TEST_SUITE="spec/path/file_eleven_spec.rb spec/path/file_twelve_spec.rb"
    num_builds: 5

#### Redistributing Files
Initially, and every so often, you will have to redistribute the spec files (make sure everything is properly set up before running this rake task). The *spec_tiller:sync* rake task adds any new spec files to the last bucket, so after a little while, the timing of the build may not be optimal. In order to redistribute the spec files in order to optimize test suite run time, run the following rake task:

    spec_tiller:redistribute

This will run your whole test suite, keeping track of how long each spec file takes to run, and the will distribute the spec files in order to maximize your test suite's run time, over the number of builds you've designated (with a default value of 5). **This rake task will not print the output of the rake task until it is complete.**

#### Ignoring Files
By default, both sync and redistribute will look for any tests following the "spec/**/*_spec.rb" pattern. If you want the tasks to ignore any specs, you can add the IGNORE_SPECS variable to your global variables. The value should be the patterns or specs you want to exclude, separated by spaces.

***
## Feature Requests & Bugs
See [http://github.com/grnhse/spec-tiller/issues](http://github.com/grnhse/spec-tiller/issues)  

## Contributing

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Add some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request
