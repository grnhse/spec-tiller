require 'spec_tiller/travis_api'

namespace :spec_tiller do
  desc 'Compares spec files in travis.yml to current list of spec files, and syncs accordingly'
  task :sync do
    SyncSpecFiles.sync
  end

  desc 'Runs whole test suite and redistributes spec files across builds according to file run time'
  task :redistribute => :environment do

    branch = ENV['branch'] ? ENV['branch'] : 'develop'

    `echo "#{branch}"`
    travis_yml_file = YAML::load(File.open('.travis.yml'))

    if branch == 'local'
      env_variables = travis_yml_file['env']['global']
      script = travis_yml_file['script'].first.gsub('$TEST_SUITE ', '')

      ignore_specs = SyncSpecFiles.get_ignored_specs(travis_yml_file).map { |spec| %Q("#{spec}") }
      script += %Q( --exclude-pattern #{ignore_specs.join(',')}) unless ignore_specs.empty?

      profile_results = `#{env_variables.join(' ')} #{script} --profile 1000000000`
    else
      profile_results = TravisAPI.get_logs(branch)
    end

    TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results) do |content|
      File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
    end

    SyncSpecFiles.sync

  end

end
