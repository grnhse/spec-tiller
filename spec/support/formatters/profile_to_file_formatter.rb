require 'rspec'
require 'rspec/core/formatters/profile_formatter'

class ProfileToFileFormatter < RSpec::Core::Formatters::ProfileFormatter
  RSpec::Core::Formatters.register(self, :dump_profile)

  def initialize(_)
    @output = File.new('/tmp/profile_results.txt', 'w')

  end

  # This class really just changes @output,
  # everything else can function as it does in ProfileFormatter
  def dump_profile(profile)
    super(profile)
  end
end
