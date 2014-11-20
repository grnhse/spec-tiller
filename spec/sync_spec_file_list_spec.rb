require 'spec_helper'
require 'yaml'

describe 'SyncSpecFiles' do

  describe '#rewrite_travis_content' do

    let(:current_file_list) do
      ['spec/test/new3.rb',
      'spec/features/space_after.rb', 'spec/features/space_before.rb',
      'spec/test/test1.rb', 'spec/test/test2.rb', 'spec/test/test3.rb', 'spec/test/test4.rb', 'spec/test/test5.rb', 'spec/test/test6.rb', 'spec/test/test7.rb', 'spec/test/test8.rb', 'spec/test/test9.rb', 'spec/test/test10.rb', 'spec/test/test11.rb', 'spec/test/test12.rb', 'spec/test/test13.rb', 'spec/test/test14.rb', 'spec/test/test15.rb', 'spec/test/test16.rb',
      'spec/test/new1.rb', 'spec/test2/new2.rb']
    end
    let(:travis_yaml) { YAML::load(File.open('spec/documents/.travis.yml')) }

    before(:each) do
      SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list)
    end

    it 'adds new files to the last line' do
      last_line = travis_yaml['env']['matrix'].last

      expect(last_line).to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
    end

    it "doesn't add new files to other lines" do
      travis_yaml['env']['matrix'][0..-2].each do |bucket|
        expect(bucket).not_to include('spec/test/new1.rb')
        expect(bucket).not_to include('spec/test2/new2.rb')
        expect(bucket).not_to include('spec/test/new3.rb')
      end

    end

    it 'removes unused specs' do
      travis_yaml['env']['matrix'].each do |bucket|
        expect(bucket).not_to include('spec/features/three_vars.rb')
      end

    end

    it 'removes unused buckets' do
      expect(travis_yaml['env']['matrix'].length).to eq(2)
    end

  end

end