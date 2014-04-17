require 'rake'
require 'yaml'

namespace :spec_distributor do
  desc 'Compares spec files in travis.yml to current list of spec files, and syncs accordingly'
  task :sync_file_list do
    content = YAML::load(File.open('.travis.yml'))
    current_file_list = Dir.glob('spec/**/*_spec.rb').map { |file_path| file_path.slice(/(spec\/\S+$)/) }
    
    rewrite_travis_content(content, current_file_list)
    `git add .travis.yml`
  end
end

def extract_spec_files(content)
  test_suites = content['env'].select { |el| el.start_with?('TEST_SUITE=') }

  test_suites.map do |test_suite|
    test_suite.gsub('TEST_SUITE=', '').gsub('"', '').split(' ')
  end
end

def delete_removed_files(spec_file_buckets, current_file_list)
  spec_file_buckets.each_with_index do |bucket, index|
    bucket.each do |spec_file|
      spec_file_buckets[index].delete(spec_file) unless current_file_list.include?(spec_file)
    end
  end
end

def add_new_files(spec_file_buckets, current_file_list)
  current_file_list.each do |spec_file|
    unless spec_file_buckets.map { |bucket| bucket.include?(spec_file) }.any? { |result| result == true }
      spec_file_buckets.last << spec_file
    end
  end

  spec_file_buckets
end

def rewrite_travis_content(content, current_file_list)
  original_spec_file_buckets = extract_spec_files(content)
  buckets_after_removed = delete_removed_files(original_spec_file_buckets, current_file_list)
  updated_spec_file_buckets = add_new_files(buckets_after_removed, current_file_list)

  content['env'] = content['env'].map { |el| el if !el.start_with?('TEST_SUITE=') }.compact

  updated_spec_file_buckets.each do |bucket|
    content['env'] << "TEST_SUITE=\"#{bucket.join(' ')}\""
  end

  File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
end
