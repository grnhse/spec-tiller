# Includes functions to parse build matrix strings into hashes and to compress them back into strings.'
module BuildMatrixParser
  def parse_env_matrix(content)
    content['env']['matrix'].map do |matrix_line|

      # Input: TEST_SUITE="spec/a.rb spec/b.rb" RUN_JS="true"
      # Output: { 'TEST_SUITE' => 'spec/a.rb spec/b.rb', 'RUN_JS' => 'true' }
      Hash[matrix_line.scan(/\s*([^=]+)="\s*([^"]+)"/)]
    end
  end
  module_function :parse_env_matrix

  def format_matrix(env_matrix)
    content_env_matrix = []

    env_matrix.each do |var_hash|
      next if var_hash.empty?
      line = var_hash.map { |key, value| %Q(#{key}="#{value}") }.join(' ')

      content_env_matrix << line
    end

    content_env_matrix
  end
  module_function :unparse_env_matrix

end