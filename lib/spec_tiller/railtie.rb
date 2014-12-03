require 'spec_tiller'
require 'rails'

module SpecTiller
  class Railtie < Rails::Railtie
    railtie_name :spec_tiller

    rake_tasks do
      load 'tasks/spec_tiller.rake'
    end
  end
end