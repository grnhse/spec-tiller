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

###### Sync

In order to make sure that the travis file remains up to date with any newly added or removed spec files, you'll have to include a rake task in your pre-commit and post-merge git hooks. Create two files in .git/hooks/ --> ``pre-commit`` and ``post-merge`` (no file extension). **Please make sure that these files are executable** (more information on [git hooks](http://git-scm.com/book/en/Customizing-Git-Git-Hooks)). In each of those two files, add the following rake task:  

    #!/bin/sh  
    rake spec_tiller:sync

Upon setting this up, any time you commit or merge, you'll notice the following output:  

    Syncing list of spec files...  
    Removed: [spec/file/removed_spec.rb]  
    Added:   [spec/file/added_spec.rb, spec/file/another_added_spec.rb]

###### Redistribute

You can also set up a hook to redistribute spec files with each commit. Because this task looks at previous travis builds for a specified branch, it's best to either add it to your post merge hook or point it to a branch that you know has builds on travis. Follow the instructions above and create a file that looks like this:

    #!/bin/sh
    rake spec_tiller:redistribute [ BRANCH='branch_name' ]

If you don't specify a branch_name, 'develop' will be used. You shouldn't use the 'local' option (see below) in a git hook - it may take a long time to run.

The sync task is called from the redistribute task, so you shouldn't need both hooks.

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
In order to keep your jobs relatively even in length (*spec_tiller:sync* rake task adds new files to a random job), you should run redistribute occasionally. Redistribute uses the rspec profile results to distribute specs into jobs that will run in roughly the same amount of time. You can call the task as specified below:

    rake spec_tiller:redistribute [ BRANCH='branch_name']

where the 'branch_name argument is optional. There are two ways to set up the redistribute task.

######Local Redistribute
This option is the most simple - it doesn't require any extra setup. The task will run your whole test suite locally and use the profile results to redistribute your files. However, because it needs to be run locally, it works best for projects with a relatively small test suite. Larger projects should use the travis setup. To run 'local' redistribute, specify 'local' as the branch name:

    rake spec_tiller:redistribute BRANCH='local'

######Travis Redistribute
This option uses profile results from past travis builds to redistribute your test suite. After it is finished running, the sync task is invoked to ensure any new files were also added. There are a few extra pieces of setup required:

  * Add the --profile 1000000000 rspec option to your travis script. This will cause travis to print all profile results in the build log. It should look something like this:

      bundle exec rspec $TEST_SUITE --tag ~local_only --profile 1000000000

  * Create a github auth key for travis and add it to your ~./bash_profile. The key should be called GITHUB_TOKEN_FOR_TRAVIS_API and should have a value of the key. You can create a key on this page: [https://github.com/settings/applications](https://github.com/settings/applications). Generate a new personal access token for travis with the following scopes:

      repo, public_repo, repo:status, read:org, read:public_key

  * Optionally, you can set up your travis script so that profile results can be folded. This will prevent your build log from getting cluttered. You'll most likely want to move your script into a separate file, then update your travis script to run from that file. See examples below:

      ``.travis.yml``:

        script: ./scripts/travis_script.sh
        after_script:
        - cat /tmp/profile_results.txt

      ``scripts/travis_script.sh``:

        #!/bin/bash

        set -v

        bundle exec rspec $TEST_SUITE --tag ~local_only --profile 1000000000 --tty | while read line
        do
          if [[ $line =~ Top.[0-9]+.slowest.examples ]]; then
            INPROF=true
            echo "$line" > /tmp/profile_results.txt
          elif [[ $line =~ Coverage.report.generated ]]; then
            INPROF=false
          elif [[ $INPROF == true ]]; then
            echo "$line" >> /tmp/profile_results.txt
          else
            echo -e "$line"
          fi
        done

To call travis redistribute, specify the branch that should be used as the base. The most recent build for the branch must have the '--profile 1000000000' option specified. If no branch is specified, 'develop' will be used. Below is an example call:

    rake spec_tiller:redistribute BRANCH='develop'

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
