require 'rake'
require 'yaml'

namespace :spec_tiller do
  desc 'Runs whole test suite and redistributes spec files across builds according to file run time'
  task :redistribute => :environment do
    travis_yml_file = YAML::load(File.open('.travis.yml'))
    env_variables = travis_yml_file['env']['global']
    script = travis_yml_file['script'].first.gsub('$TEST_SUITE ', '')

    profile_results = `#{env_variables.join(' ')} #{script} --profile 1000000000`

    `echo "#{profile_results}" > spec/log/rspec_profile_output.txt`
    TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results)
    puts profile_results
  end
end

module TravisBuildMatrix

  DEFAULT_NUM_BUILDS = 5

    class SpecFile
      attr_accessor :file_path, :test_duration

      def initialize(file_path, test_duration)
        @test_duration = test_duration
        @file_path = file_path
      end
    end

    class TestBucket
      attr_reader :spec_files, :total_duration

      def initialize
        @total_duration = 0.0
        @spec_files = []
      end

      def add_to_list(spec_file)
        @spec_files << spec_file
        @total_duration += spec_file.test_duration
      end
    end

    class SpecDistributor
      EXTRACT_DURATION_AND_FILE_PATH = /\s{1}\(([0-9\.]*\s).*\.\/(spec.*):/

      def initialize(travis_yml_file, profile_results)
        num_buckets = travis_yml_file['num_builds'] || DEFAULT_NUM_BUILDS

        @spec_files = parse_profile_results(profile_results)
        @test_buckets = Array.new(num_buckets){ |_| TestBucket.new }
        
        distribute_tests

        TravisBuildMatrix::TravisFile.new(@test_buckets, travis_yml_file)
      end

      private

        def parse_profile_results(profile_results)
          extracted_info = profile_results.scan(EXTRACT_DURATION_AND_FILE_PATH).uniq { |spec_file| spec_file.last }
          
          tests = extracted_info.map do |capture_groups|
            test_duration = capture_groups.first.strip.to_f
            test_file_path = capture_groups.last
            
            SpecFile.new(test_file_path, test_duration)
          end

          tests.sort_by(&:test_duration).reverse
        end

        def smallest_bucket
          @test_buckets.min_by(&:total_duration)
        end

        def distribute_tests
          @spec_files.each { |test| smallest_bucket.add_to_list(test) }
        end

    end

    class TravisFile
      def initialize(test_buckets, travis_yml_file)
        rewrite_content(test_buckets, travis_yml_file)
      end

      private

        def rewrite_content(test_buckets, content)
          content['env']['matrix'] ||= [] # initialize env if not already set
          other_vars = [] # used with regex below to store extra vars
          test_suite_regex = /TEST_SUITE=".+rb"/

          content['env']['matrix'] = content['env']['matrix'].map do |el|

            test_suite_str = el.split(test_suite_regex).join.strip
            other_vars.push(test_suite_str) # add extra vars to array if they exist

            el unless el.start_with?('TEST_SUITE=')
          end.compact

          other_vars.compact

          test_buckets.each_with_index do |test_bucket, index|
            spec_file_list = test_bucket.spec_files.map(&:file_path).join(' ')

            test_suite = "TEST_SUITE=\"#{spec_file_list}\""

            # adds extra variables back to previous line, ignores if number of lines is less now
            if other_vars.length > index do
              test_suite += other_vars[index]
            end
            end

            content['env']['matrix'] << test_suite
          end

          File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
        end

      private

        def split_vars(matrix_var_array)

          matrix_var_hash_array = []
          matrix_var_array.each do |row|
            row_var_array = row.split(' ')
            row_hash = {}

            row_var_array.each do |var_set_s|
              var_set_array = var_set_s.split('=')
              row_hash[var_set_array[0]] = var_set_array[1]
            end

            matrix_var_hash_array.push(row_hash)
          end

          return matrix_var_hash_array
        end

    end
  
end
