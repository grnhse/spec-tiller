require 'rake'
require 'yaml'

namespace :spec_tiller do
  desc 'Compares spec files in travis.yml to current list of spec files, and syncs accordingly'
  task :sync do
    content = YAML::load(File.open('.travis.yml'))
    current_file_list = Dir.glob('spec/**/*_spec.rb').map { |file_path| file_path.slice(/(spec\/\S+$)/) }
    
    puts "\nSyncing list of spec files..."
    puts rewrite_travis_content(content, current_file_list) # returns the file list diff

    `git add .travis.yml`
  end
end

def rewrite_travis_content(content, current_file_list)
  original = extract_spec_files(content)
  after_removed = delete_removed_files(original, current_file_list)
  after_added = add_new_files(original, after_removed, current_file_list)

  content['env'] = content['env'].map { |el| el if !el.start_with?('TEST_SUITE=') }.compact

  after_added.each do |bucket|
    content['env'] << "TEST_SUITE=\"#{bucket.join(' ')}\""
  end

  File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
  file_diff(original, current_file_list)
end

private

  def extract_spec_files(content)
    test_suites = content['env'].select { |el| el.start_with?('TEST_SUITE=') }

    test_suites.map do |test_suite|
      test_suite.gsub('TEST_SUITE=', '').gsub('"', '').split(' ')
    end
  end

  def delete_removed_files(original, current_file_list)
    deleted_files = deleted_files(original, current_file_list)

    original.map do |bucket|
      bucket.reject { |spec_file| deleted_files.include?(spec_file) }
    end
  end

  def add_new_files(original, buckets, current_file_list)
    buckets_clone = buckets.map(&:dup)

    added_files(original, current_file_list).each do |spec_file|
      buckets_clone.last << spec_file
    end

    buckets_clone
  end

  def deleted_files(original, current_file_list)
    original.flatten - current_file_list
  end

  def added_files(original, current_file_list)
    current_file_list - original.flatten
  end

  def file_diff(original, current_file_list)
    {
      :removed => deleted_files(original, current_file_list).sort,
      :added => added_files(original, current_file_list).sort
    }
  end