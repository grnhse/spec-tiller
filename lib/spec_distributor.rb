require "spec_distributor/version"
require 'yaml'

module SpecDistributor
  
  DEFAULT_NUM_BUILDS = 5

  travis_yml_file = YAML::load(File.open('.travis.yml'))
  profile_results = ARGF.read

  # module TravisBuildMatrix
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

    class TestDistributor
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
          content['env'] ||= [] # initialize env if not already set
          content['env'] = content['env'].map { |el| el if !el.start_with?('TEST_SUITE=') }.compact

          test_buckets.each_with_index do |test_bucket, index|
            spec_file_list = test_bucket.spec_files.map(&:file_path).join(' ')

            content['env'] << "TEST_SUITE=\"#{spec_file_list}\""
          end

          File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
        end

    end
  # end

  SpecDistributor::TestDistributor.new(travis_yml_file, profile_results)
end
