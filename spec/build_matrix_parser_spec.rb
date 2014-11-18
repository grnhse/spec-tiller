require 'spec_helper'
require 'yaml'

describe BuildMatrixParser do

  let(:travis_yml_file) { YAML::load(File.open('spec/documents/.travis.yml')) }

  describe '#parse_env_matrix' do
    let(:actual_parsed_matrix) { BuildMatrixParser.parse_env_matrix(travis_yml_file) }

    it 'will maintain same number of elements' do
      expect(actual_parsed_matrix.length).to eq(5)
    end
    it 'will parse multiple variables' do
      expect(actual_parsed_matrix[0]).to eq( { "TEST_SUITE" => "spec/features/three_vars.rb", "RUN_JS" => "true", "FAKE_VAR" => "fake.value.rb" } )
    end
    it 'will ignore extra spaces' do
      expect(actual_parsed_matrix[1]).to eq( { "TEST_SUITE" => "spec/features/space_after.rb      spec/features/space_before.rb", "FIVE_TABS_BEFORE" => "tabs are ignored" } )
    end
    it 'will parse lowercase, numbers, and symbols' do
      expect(actual_parsed_matrix[2]).to eq( { "l0w3rC@5e&nUm5&sym()1s" => "~!@#$%^&*()_+1234567890-=`{}[]|:;''<>,.?/", "TEST_SUITE" => "spec/features/test.rb" } )
    end
    it 'will parse empty lines' do
      expect(actual_parsed_matrix[3]).to eq( {} )
    end
    it 'will parse long file lists' do
      expect(actual_parsed_matrix[4]).to eq( { "TEST_SUITE" => "spec/test/test1.rb spec/test/test2.rb spec/test/test3.rb spec/test/test4.rb spec/test/test5.rb spec/test/test6.rb spec/test/test7.rb spec/test/test8.rb spec/test/test9.rb spec/test/test10.rb spec/test/test11.rb spec/test/test12.rb spec/test/test13.rb spec/test/test14.rb spec/test/test15.rb spec/test/test16.rb" } )
    end
  end

  describe '#format_matrix' do
    let(:actual_formatted_matrix) { BuildMatrixParser.format_matrix(BuildMatrixParser.parse_env_matrix(travis_yml_file)) }

    it 'will maintain multiple variables' do
      expect(actual_formatted_matrix[0]).to eq(%Q(TEST_SUITE="spec/features/three_vars.rb" RUN_JS="true" FAKE_VAR="fake.value.rb"))
    end
    it 'will strip spaces' do
      expect(actual_formatted_matrix[1]).to eq(%Q(TEST_SUITE="spec/features/space_after.rb      spec/features/space_before.rb" FIVE_TABS_BEFORE="tabs are ignored"))
    end
    it 'will maintain lowercase, numbers, and symbols' do
      expect(actual_formatted_matrix[2]).to eq(%Q(l0w3rC@5e&nUm5&sym()1s="~!@#$%^&*()_+1234567890-=`{}[]|:;''<>,.?/" TEST_SUITE="spec/features/test.rb"))
    end
    it 'will remove empty lines' do
      expect(actual_formatted_matrix[3]).to_not eq(nil)
    end
    it 'will maintain long file lists' do
      expect(actual_formatted_matrix[3]).to eq(%Q(TEST_SUITE="spec/test/test1.rb spec/test/test2.rb spec/test/test3.rb spec/test/test4.rb spec/test/test5.rb spec/test/test6.rb spec/test/test7.rb spec/test/test8.rb spec/test/test9.rb spec/test/test10.rb spec/test/test11.rb spec/test/test12.rb spec/test/test13.rb spec/test/test14.rb spec/test/test15.rb spec/test/test16.rb"))
    end
  end

end
