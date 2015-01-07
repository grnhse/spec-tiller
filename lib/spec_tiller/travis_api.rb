require 'travis'

class TravisAPI

  def self.get_logs
    client = Travis::Client.new('https://api.travis-ci.com')
    client.github_auth('09be1b4efc00b3d13cbd103b6d0fcc367a52d638')
    repository = client.repo('grnhse/greenhouse')
    last_build = nil

    repository.each_build do |build|
      next unless build.state == 'passed' || build.state == 'failed'
      if build.commit.branch == 'feature/testing-spec-tiller-travis-api'
        last_build = build
        break
      end
    end

    profile_results = ''

    last_build.jobs.each do |job|
      profile_results += job.log.body
    end

    profile_results
  end
end