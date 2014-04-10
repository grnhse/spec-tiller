namespace :spec_distributor do
  desc "Runs whole test suite and redistributes spec files across builds according to file run time"
  task :redistribute => :environment do
    `rspec --profile 1000000000 | ruby #{Rails.root}/script/spec_files/spec_distributor.rb`
  end
end