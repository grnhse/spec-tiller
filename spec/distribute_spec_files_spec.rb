require 'spec_helper'
require 'yaml'

describe 'TravisBuildMatrix' do

  describe 'TestBucket' do
    let(:bucket) { TestBucket.new }

    describe '::new' do

      it 'will have an initial duration of 0.0' do
        expect(bucket.total_duration).to eq(0.0)
      end
      it 'will begin with an empty file list' do
        expect(bucket.spec_files).to eq([])
      end
    end

    describe '#add_to_list' do
      let(:short_spec_file) { SpecFile.new('spec/features/short_spec_file.rb', 3.2) }
      let(:long_spec_file) { SpecFile.new('spec/features/long_spec_file.rb', 10.4)}
      bucket.add_to_list(short_spec_file)
      bucket.add_to_list(long_spec_file)

      it 'adds to bucket duration' do
        expect(bucket.total_duration).to eq(13.6)
      end
      it 'adds all files' do
        expect(bucket.spec_files.length).to eq(2)
      end
      it 'maintains file order' do
        expect(bucket.spec_files.first).to be(short_spec_file.file_path)
      end
    end
  end

  describe 'SpecDistributor' do
    let(:travis_yml_file) { YAML::load(File.open('spec/documents/.travis.yml')) }
    let(:profile_results) { File.open('spec/documents/.profile_results.txt') }

    describe '::new' do

    end

    describe '#parse_profile_results' do

    end

    describe '#smallest_bucket' do

    end

    describe '#distribute_tests' do

    end

  end

  describe 'TravisFile' do

    describe '#initialize' do

    end

    describe '#rewrite_content' do

    end

  end

end