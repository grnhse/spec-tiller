# Includes functions to parse build matrix strings into hashes and to compress them back into strings.'
module BuildMatrixParser
  module_function :parse_env_matrix, :format_matrix, :nil_or_empty?, :contains_suite_env_var

  def parse_env_matrix(content)
    content['env']['matrix'].map do |matrix_line|
      if matrix_line.nil?
        {}
      else
        # Input: TEST_SUITE="spec/a.rb spec/b.rb" RUN_JS="true"
        # Output: { 'TEST_SUITE' => 'spec/a.rb spec/b.rb', 'RUN_JS' => 'true' }
        Hash[matrix_line.scan(/\s*([^=]+)="\s*([^"]+)"/)]
      end
    end
  end

  def format_matrix(env_matrix)
    content_env_matrix = []

    env_matrix.each do |var_hash|
      next if nil_or_empty?(var_hash)
      line = var_hash.map { |key, value| %(#{key}="#{value}") }.join(' ')
      content_env_matrix << line
    end
    content_env_matrix
  end

  def nil_or_empty?(var_hash)
    return true if var_hash.empty? || contains_suite_env_var(var_hash)
    var_hash['TEST_SUITE'].empty? unless var_hash['TEST_SUITE'].nil?
  end

  def contains_suite_env_var(var_hash)
    var_hash.keys.grep(/SUITE/).empty?
  end
end
