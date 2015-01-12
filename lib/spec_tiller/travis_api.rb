require 'travis'

class TravisAPI

  def self.get_logs(branch)
    client = Travis::Client.new('https://api.travis-ci.com')
    client.github_auth(ENV['GITHUB_TOKEN_FOR_TRAVIS_API'])
    repository = client.repo('grnhse/greenhouse')
    last_build = nil

    repository.each_build do |build|
      next unless build.state == 'passed' || build.state == 'failed'
      if build.commit.branch == branch
        last_build = build
        break
      end
    end

    raise 'No previous builds found for specified branch.' if build.nil?

    profile_results = ''

    last_build.jobs.each do |job|
      body = job.log.body
      profile_results += job.log.body if body
    end

    profile_results
  end
end