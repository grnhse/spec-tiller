require 'travis'

class TravisAPI

  def self.get_logs(branch)
    client = Travis::Client.new('https://api.travis-ci.com')
    client.github_auth(ENV.fetch('GITHUB_TOKEN_FOR_TRAVIS_API'))
    repository = client.repo(current_repo)

    raise 'Repository not found. Ensure Fetch URL of "git remote show origin" points to your repository.' if repository.nil?

    raise "Branch #{branch} not found in current repository." unless repository.branches.key?(branch)

    last_build = most_recent_build_for(repository, branch)

    logs_for(last_build)
  end



    def self.current_repo
      # Input:
      #   ...
      #   Fetch URL: git@github.com:grnhse/spec-tiller.git
      #   ...
      # Output: grnhse/spec-tiller
      `cd ../greenhouse; git remote show -n origin`.match(/Fetch URL: .*:(.+).git/)[1]
    end

    def self.most_recent_build_for(repository, branch)
      repository.each_build do |build|
        if build.commit.branch == branch && build.state == 'passed'
          return build
        end
      end

      raise "No passing builds found for #{branch}."
    end

    def self.logs_for(build)
      build.
        jobs.
        map{ |j| j.log.body }.
        compact.
        join('\n')
    end
end
