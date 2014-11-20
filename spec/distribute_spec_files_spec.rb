require 'spec_helper'
require 'yaml'

describe 'TravisBuildMatrix' do

  describe 'TestBucket' do
    let(:bucket) { TravisBuildMatrix::TestBucket.new }

    describe '::new' do

      it 'will have an initial duration of 0.0' do
        expect(bucket.total_duration).to eq(0.0)
      end

      it 'will begin with an empty file list' do
        expect(bucket.spec_files).to eq([])
      end

    end

    describe '#add_to_list' do
      let(:short_spec_file) { TravisBuildMatrix::SpecFile.new('spec/features/short_spec_file.rb', 3.2) }
      let(:long_spec_file) { TravisBuildMatrix::SpecFile.new('spec/features/long_spec_file.rb', 10.4) }
      before(:each) do
        bucket.add_to_list(short_spec_file)
        bucket.add_to_list(long_spec_file)
      end

      it 'adds to bucket duration' do
        expect(bucket.total_duration.round(1)).to eq(13.6)
      end

      it 'adds all files' do
        expect(bucket.spec_files.length).to eq(2)
      end

      it 'maintains file order' do
        expect(bucket.spec_files.first).to be(short_spec_file)
      end

    end

  end

  describe 'SpecDistributor' do
    let!(:travis_yml_file) { YAML::load(File.open('spec/documents/.travis.yml')) }
    let(:profile_results) { File.read('spec/documents/rspec_profile_results.txt') }

    describe '::new' do
      before(:each) do
        allow(File).to receive(:open).and_return(true)
      end

      it 'defaults to 5 builds' do
        travis_yml_file['num_builds'] = nil
        TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results)
        expect(travis_yml_file['env']['matrix'].length).to eq(5)
      end

      it 'runs when there are more builds than specs' do
        travis_yml_file['num_builds'] = 20
        TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results)
        expect(travis_yml_file['env']['matrix'].length).to eq(10) # 10 is the number of builds in profile results.
      end

      it 'can find special characters' do
        travis_yml_file['num_builds'] = 1
        TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results)
        expect(travis_yml_file['env']['matrix'].first).to include(%Q(~!@#$^()_+1234567890-=`{}[];',_spec.rb))
      end
      
      it 'groups builds as expected' do
        travis_yml_file['num_builds'] = 5
        TravisBuildMatrix::SpecDistributor.new(travis_yml_file, profile_results)
        formatted_matrix = travis_yml_file['env']['matrix']
        expect(formatted_matrix[0]).to include('different_ending.rb')
        expect(formatted_matrix[1]).to include('peanut_spec.rb')
        expect(formatted_matrix[2]).to include('almond_spec.rb')
        expect(formatted_matrix[3]).to include('cashew_spec.rb')
        expect(formatted_matrix[4]).to include(%Q(~!@#$^()_+1234567890-=`{}[];',_spec.rb))
        expect(formatted_matrix[4]).to include('different_extension_spec.txt')
        expect(formatted_matrix[3]).to include('pecan_spec.rb')
        expect(formatted_matrix[4]).to include('walnut_spec.rb')
        expect(formatted_matrix[3]).to include('acorn_spec.rb')
        expect(formatted_matrix[3]).to include('pistachio_spec.rb')
      end

    end

  end

  describe 'TravisFile' do

    describe '::new' do

      def create_bucket(total_duration, spec_file_list)
        bucket = TravisBuildMatrix::TestBucket.new
        bucket.instance_variable_set("@total_duration", total_duration)
        spec_file_hashes = spec_file_list.map do |file|
          TravisBuildMatrix::SpecFile.new(file, 0) # don't care about duration, not used in this test
        end
        bucket.instance_variable_set("@spec_files", spec_file_hashes)
        bucket
      end

      let!(:travis_yml_file) { YAML::load(File.open('spec/documents/.travis.yml')) }

      let(:test_buckets) do
        [create_bucket(8, ['spec/features/three_vars.rb']),
         create_bucket(8.3, ['spec/features/space_after.rb', 'spec/features/space_before.rb']),
         create_bucket(11.8, ['spec/features/test.rb']),
         create_bucket(10.7, ['spec/test/test1.rb', 'spec/test/test2.rb', 'spec/test/test3.rb', 'spec/test/test4.rb', 'spec/test/test5.rb', 'spec/test/test6.rb', 'spec/test/test7.rb', 'spec/test/test8.rb', 'spec/test/test9.rb', 'spec/test/test10.rb', 'spec/test/test11.rb', 'spec/test/test12.rb', 'spec/test/test13.rb', 'spec/test/test14.rb', 'spec/test/test15.rb', 'spec/test/test16.rb']),
         create_bucket(10.4, ['spec/features/long_spec.rb']),
         create_bucket(9.1, ['spec/features/short_1_spec.rb', 'spec/features/short_2_spec.rb', 'spec/features/short_3_spec.rb'])]
      end

      before(:each) do
        allow(File).to receive(:open).and_return(true)
      end

      context 'buckets are removed' do
        before(:each) do
          TravisBuildMatrix::TravisFile.new(test_buckets[0..1], travis_yml_file)
        end

        it 'compresses to the appropriate size' do
          expect(travis_yml_file['env']['matrix'].length).to eq(2)
        end

        it 'maintains env variables within range' do
          formatted_matrix = travis_yml_file['env']['matrix']
          expect(formatted_matrix[0]).to include(%Q(RUN_JS="true"))
          expect(formatted_matrix[0]).to include(%Q(FAKE_VAR="fake.value.rb"))
          expect(formatted_matrix[1]).to include(%Q(FIVE_TABS_BEFORE="tabs are ignored"))
        end

        it 'drops env variables outside of range' do
          travis_yml_file['env']['matrix'].each do |line|
            expect(line).to_not include(%Q(l0w3rC@5e&nUm5&sym()1s="~!@#$%^&*()_+1234567890-=`{}[]|:;''<>,.?/"))
          end

        end

      end

      context 'buckets are added' do
        before(:each) do
          TravisBuildMatrix::TravisFile.new(test_buckets, travis_yml_file)
        end

        it 'expands to appropriate size' do
          expect(travis_yml_file['env']['matrix'].length).to eq(6)
        end

        it 'maintains env variables within range' do
          formatted_matrix = travis_yml_file['env']['matrix']
          expect(formatted_matrix[0]).to include(%Q(RUN_JS="true"))
          expect(formatted_matrix[0]).to include(%Q(FAKE_VAR="fake.value.rb"))
          expect(formatted_matrix[1]).to include(%Q(FIVE_TABS_BEFORE="tabs are ignored"))
          expect(formatted_matrix[2]).to include(%Q(l0w3rC@5e&nUm5&sym()1s="~!@#$%^&*()_+1234567890-=`{}[]|:;''<>,.?/"))
        end

      end

    end

  end

end