require 'uri'

class Service::BacklogV2 < Service
  string   :base_url
  password :api_key
  white_list :base_url

  def receive_push
    if data['base_url'].to_s.empty?
      raise_config_error "Backlog base URL not set"
    end
    if data['api_key'].to_s.empty?
      raise_config_error "apiKey not set"
    end

    repository = payload['repository']['url'].to_s
    commits = payload['commits'].collect{|c| Commit.new(c)}
    issue_commits = sort_commits(commits)
    issue_commits.sort.map do | issue, commits |
      post(issue, repository, commits, branch.to_s)
    end

  end

  def branch
    return @branch if defined?(@branch)

    matches = payload['ref'].match(/^refs\/heads\/(.*)$/)
    @branch = matches ? matches[1] : nil
  end

  def sort_commits(commits)
    issue_commits = Hash.new{|k,v| k[v] = []}
    commits.each do |commit|
      commit.issue.each do |issue|
        issue_commits[issue] << commit
      end
    end
    return issue_commits
  end

  def post(issue, repository, commits, branch_name)
    if commits.length == 0
      return
    end

    branch_str = branch_name.empty? ? "" : "#{branch_name} at "
    message = "pushed to #{branch_str}#{repository}\n\n"

    commits.each do |commit|
      comment = "#{message}#{commit.comment}"
      if commit.status
        path = "/api/v2/issues/%s" % issue
        http.url_prefix = data['base_url']
        http.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        res = http_post path, {:apiKey => data['api_key'], :comment => comment, :status => commit.status}

        if res.status != 200
          raise_config_error "failed post"
        end

      else
        path = "/api/v2/issues/%s/comments" % issue
        http.url_prefix = data['base_url']
        http.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        res = http_post path % [ issue ], {:apiKey => data['api_key'], :content => comment}

        if res.status != 200
          raise_config_error "failed post"
        end
      end

    end
  end

  class Commit
    attr_reader :status, :issue, :url, :id

    def initialize(commit_hash)
      @id = commit_hash['id'].to_s
      @url = commit_hash['url'].to_s
      @message = commit_hash['message'].to_s
      @status = nil
      @issue = []

      re_issue_key = /(?:\[\[)?(([A-Z0-9]+(?:_[A-Z0-9]+)*)-([1-9][0-9]*))(?:\]\])?/
      temp = @message
      while temp =~ re_issue_key
        issue << $1
        temp.sub!($1, '')
      end

      re_status = /(?:^|\s+?)(#fixes|#fixed|#fix|#closes|#closed|#close)(?:\s+?|$)/
      while @message =~ re_status
        switch = $1
        @message.sub!(switch, '')
        @status = (switch =~ /fix/) ? 3 : 4
      end
    end

    def comment()
      output = "#{@url}\n"
      output += @message.strip
      return output
    end
  end
end
