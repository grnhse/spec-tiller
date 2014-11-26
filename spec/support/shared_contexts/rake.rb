# From http://robots.thoughtbot.com/test-rake-tasks-like-a-boss and
require 'rake'

shared_context 'rake' do
  let(:rake) { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/tasks/#{task_name.split(":").first}" }
  subject(:task) { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $".reject { |file| file == [Dir.pwd].join("#{task_path}.rake").to_s }
  end

  before(:each) do
    original_open = File.method(:open)
    allow(File).to receive(:open) do |file_name, options, &block|
      file_name = 'spec/documents/.travis2.yml' if file_name == '.travis.yml'
      original_open.call(file_name, options, &block)
    end

    Rake.application = rake
    Rake.application.rake_require(task_path, [Dir.pwd], loaded_files_excluding_current_rake_file)

    Rake::Task.define_task(:environment)
  end
end