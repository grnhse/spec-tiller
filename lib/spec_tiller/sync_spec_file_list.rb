require 'rake'
require 'yaml'

namespace :spec_tiller do
  desc 'Compares spec files in travis.yml to current list of spec files, and syncs accordingly'
  task :sync do
    content = YAML::load(File.open('.travis.yml'))
    current_file_list = Dir.glob('spec/**/*_spec.rb').map { |file_path| file_path.slice(/(spec\/\S+$)/) }
    
    puts "\nSyncing list of spec files..."
    puts SyncSpecFiles.rewrite_travis_content(content, current_file_list) # returns the file list diff

    `git add .travis.yml`
  end
end

module SyncSpecFiles
  include BuildMatrixParser

  def rewrite_travis_content(content, current_file_list)
    env_matrix = BuildMatrixParser.parse_env_matrix(content)
    original = extract_spec_files(env_matrix)
    after_removed = delete_removed_files(original, current_file_list)
    after_added = add_new_files(original, after_removed, current_file_list)

    env_matrix.each do |var_hash|
      test_bucket = after_added.shift
      break if test_bucket.nil?

      var_hash['TEST_SUITE'] = "#{test_bucket.join(' ')}"
    end

    content['env']['matrix'] = BuildMatrixParser.unparse_env_matrix(env_matrix)

    File.open('.travis.yml', 'w') { |file| file.write(content.to_yaml(:line_width => -1)) }
    file_diff(original, current_file_list)
  end
  module_function :rewrite_travis_content

  private

    def self.extract_spec_files(env_matrix)
      test_suites = env_matrix.map do |var_hash|
        var_hash['TEST_SUITE'].gsub('"', '').split(' ') if var_hash.has_key?('TEST_SUITE')
      end

      test_suites.compact
    end

    def self.delete_removed_files(original, current_file_list)
      deleted_files = deleted_files(original, current_file_list)

      original.map do |bucket|
        bucket.reject { |spec_file| deleted_files.include?(spec_file) }
      end
    end

    def self.add_new_files(original, buckets, current_file_list)
      buckets_clone = buckets.map(&:dup)

      added_files(original, current_file_list).each do |spec_file|
        buckets_clone.last << spec_file
      end

      buckets_clone
    end

    def self.deleted_files(original, current_file_list)
      original.flatten - current_file_list
    end

    def self.added_files(original, current_file_list)
      current_file_list - original.flatten
    end

    def self.file_diff(original, current_file_list)
      removed_files = deleted_files(original, current_file_list).sort
      removed = removed_files.empty? ? 'No spec files removed' : removed_files

      added_files = added_files(original, current_file_list).sort
      added = added_files.empty? ? 'No spec files added' : added_files

      "  Removed: #{removed}\n  Added:   #{added}\n\n"
    end
end