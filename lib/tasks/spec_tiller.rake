namespace :spec_tiller do
  desc 'Compares spec files in travis.yml to current list of spec files, and syncs accordingly'
  task :sync do
    content = YAML::load(File.open('.travis.yml'))
    current_file_list = Dir.glob('spec/**/*_spec.rb').map { |file_path| file_path.slice(/(spec\/\S+$)/) }

    puts "\nSyncing list of spec files..."

    SyncSpecFiles.rewrite_travis_content(content, current_file_list) do |content, original, current_file_list|
      File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
      puts SyncSpecFiles.file_diff(original, current_file_list)
    end

    `git add .travis.yml`
  end

  desc 'Runs whole test suite and redistributes spec files across builds according to file run time'
  task :redistribute => :environment do
    travis_yml_file = YAML::load(File.open('.travis.yml'))
    env_variables = travis_yml_file['env']['global']
    script = travis_yml_file['script'].first.gsub('$TEST_SUITE ', '')
    ignore_specs = SyncSpecFiles.get_ignored_specs(travis_yml_file).map { |spec| %Q("#{spec}") }
    script += %Q( --exclude-pattern #{ignore_specs.join(',')}) unless ignore_specs.empty?

    profile_results = `#{env_variables.join(' ')} #{script} --profile 1000000000`

    `echo "#{profile_results}" > spec/log/rspec_profile_output.txt`
    TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results) do |content|
      File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
    end

    puts profile_results
  end

end