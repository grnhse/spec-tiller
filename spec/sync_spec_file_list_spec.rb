require 'spec_helper'
require 'yaml'

describe 'SyncSpecFiles' do

  describe '#rewrite_travis_content' do

    let(:current_file_list) do
      ['spec/test/new3.rb',
      'spec/features/ignore_me.rb',
      'spec/features/space_after.rb', 'spec/features/space_before.rb',
      'spec/test/test1.rb', 'spec/test/test2.rb', 'spec/test/test3.rb', 'spec/test/test4.rb', 'spec/test/test5.rb', 'spec/test/test6.rb', 'spec/test/test7.rb', 'spec/test/test8.rb', 'spec/test/test9.rb', 'spec/test/test10.rb', 'spec/test/test11.rb', 'spec/test/test12.rb', 'spec/test/test13.rb', 'spec/test/test14.rb', 'spec/test/test15.rb', 'spec/test/test16.rb',
      'spec/test/new1.rb', 'spec/test2/new2.rb']
    end
    let(:travis_yaml) { YAML::load(File.open('spec/documents/.travis.yml')) }

    describe 'Static Yaml' do
      before(:each) do
        SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list)
      end

      it 'adds new files to random line' do
        expect(travis_yaml['env']['matrix'].join(' ')).to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
      end

      it 'removes unused specs' do
        travis_yaml['env']['matrix'].each do |bucket|
          expect(bucket).not_to include('spec/features/three_vars.rb')
        end

      end

      it 'removes lines without a *SUITE variable' do
        expect(travis_yaml['env']['matrix'].grep(/SUITE/).count).to eq(5)
      end

      it 'does not include ignored specs' do
        travis_yaml['env']['matrix'].each do |bucket|
          expect(bucket).not_to include('spec/features/ignore_me.rb')
        end
      end
    end

    describe 'Modified Yaml' do
      describe 'Respects num_builds in syncing files' do
        it 'when num_builds: 1, adds files to only the first two lines of the matrix' do
          travis_yaml['num_builds'] = 1
          SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list) do |yaml|
            matrix =  yaml['env']['matrix']
            first_bucket = matrix.first
            rest_buckets = matrix[1..-1].join(' ')

            expect(first_bucket).to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
            expect(rest_buckets).not_to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
          end
        end

        it 'when num_builds: 2, adds files to only the first 2 lines of the matrix' do
          travis_yaml['num_builds'] = 2
          SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list) do |yaml|
          matrix = yaml['env']['matrix']
          first_two_buckets = matrix[0..1].join(' ')
          rest_buckets = matrix[2..-1].join(' ')

          expect(first_two_buckets).to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
          expect(rest_buckets).not_to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
          end
        end

        it 'when num_builds > current bucket count it uses current bucket count' do
          travis_yaml['num_builds'] = 100
          SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list) do |yaml|
            matrix = yaml['env']['matrix']
            buckets = matrix.join(' ')
            expect(buckets).to include('spec/test/new1.rb','spec/test2/new2.rb','spec/test/new3.rb')
          end
        end

        it 'when num-builds < current bucket count it ignores later buckets' do
          travis_yaml['num_builds'] = 5

          SyncSpecFiles.rewrite_travis_content(travis_yaml, current_file_list) do |yaml| 
            matrix = yaml['env']['matrix']
            last_bucket = matrix.last
            second_to_last_bucket = matrix[-2]
            expect(last_bucket).to eq("SAUCE_SUITE=\"apsec2.rb aspec3.rb\" SAUCE_SUITE_BROWSERS=\"IE 5\"")
            expect(second_to_last_bucket).to eq("SAUCE_SUITE=\"random_spec_1.rb random_spec_2.rb\" SAUCE_SUITE_BROWSERS=\"something else here\"")
          end
        end
      end
    end
  end
end
