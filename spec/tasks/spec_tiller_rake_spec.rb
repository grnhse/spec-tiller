require 'spec_helper'
require 'support/shared_contexts/rake'
require 'yaml'

describe 'spec_tiller:sync' do
  include_context('rake')
  before(:each) do
    original_glob = Dir.method(:glob)
    allow(Dir).to receive(:glob) do |pattern|
      pattern = 'spec/documents/*_spec.rb' if pattern == 'spec/**/*_spec.rb'
      original_glob.call(pattern)
    end
  end

  it 'adds new files to random line' do
    temp_file_name = 'spec/documents/new_added_spec.rb'
    File.new(temp_file_name, 'w')
    content_at_start = YAML::load(File.open('.travis.yml'))

    task.invoke
    content_at_end = YAML::load(File.open('.travis.yml'))
    expect(content_at_end['env']['matrix'].join(' ')).to include(temp_file_name)

    # Clean up added file and travis.yml
    File.delete(temp_file_name)
    File.open('.travis.yml', 'w') { |file| file.write(content_at_start.to_yaml(:line_width => -1)) }
  end

  it 'removes non-existent files' do
    temp_file_name = 'spec/documents/old_removed_spec.rb'
    content_at_start = YAML::load(File.open('.travis.yml'))
    content_at_start['env']['matrix'] << %Q(TEST_SUITE="#{temp_file_name}")
    File.open('.travis.yml', 'w') { |file| file.write(content_at_start.to_yaml(:line_width => -1)) }

    task.invoke
    content_at_end = YAML::load(File.open('.travis.yml'))

    content_at_end['env']['matrix'].each do |bucket|
      expect(bucket).to_not include(temp_file_name)
    end

  end

end

describe 'spec_tiller:redistribute' do
  include_context('rake')
  before do
    allow(SyncSpecFiles).to receive(:sync)
  end

  it 'distributes evenly based on run time' do
    content_at_start = YAML::load(File.open('.travis.yml'))
    ENV['BRANCH'] = 'local'
    task.invoke
    content_at_end = YAML::load(File.open('.travis.yml'))

    expect(content_at_end['env']['matrix']).to eq(content_at_start['env']['matrix'])
    expect(content_at_end['env']['matrix'].length).to eq(2)
  end

end
