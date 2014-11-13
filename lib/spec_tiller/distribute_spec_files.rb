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

          matrix_var_hash_array = split_vars(content['env']['matrix']) # split var strings into hashes

          content['env']['matrix'] = content['env']['matrix'].map do |el|
            el unless el.include?('TEST_SUITE=')
          end.compact

          i = 0 # used to track row in matrix_var_hash_array
          test_buckets.each_with_index do |test_bucket, index|

            i = find_row_with_var(matrix_var_hash_array, i)
            spec_file_list = test_bucket.spec_files.map(&:file_path).join(' ')

            if i != -1
              matrix_var_hash_array[i][:TEST_SUITE] = "\"#{spec_file_list}\""
              i += 1
              test_suite = ''
              matrix_var_hash_array[i].each do |key,value|
                test_suite += "#{key}=#{value} "
              end
            else
              test_suite = "TEST_SUITE=\"#{spec_file_list}\""
            end

            content['env']['matrix'] << test_suite
          end

          File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
        end

        def split_vars(matrix_var_array)

          matrix_var_array.map do |row|
            row_var_sets = row.split(' ')
            row = {}

            row_var_sets.each do |var_set_s|
              var_set_array = var_set_s.split('=')
              row[var_set_array[0]] = var_set_array[1]
            end

            row
          end

          matrix_var_array
        end

      def find_row_with_var(var_hash_array, start_index = 0, var_to_find = 'TEST_SUITE')

        if start_index < var_hash_array.length
          if var_hash_array[start_index].has_value?(var_to_find) { start_index }

          else find_row_with_var(var_hash_array, start_index + 1)

          end
        else -1
        end
      end

    end
  
end
