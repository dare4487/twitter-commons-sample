=begin
    Provides API accessors for operations over github repos
    This module has several methods that interface with Git and github
     Unless otherwise returned specifically with a status,, commands that don't fail return an empty string - ''
=end

module GithubApi

  def GithubApi.CreateNewBranch new_branch, branch
    puts "Creating new branch #{new_branch} from #{branch}..."
    `git branch #{new_branch} #{branch}`
  end

  def GithubApi.CheckoutNewBranch branch
    puts "Checking out new branch #{branch}..."
    `git checkout -b #{branch}`
  end

  def GithubApi.CheckoutExistingBranch branch
    puts "Checking out existing branch #{branch}..."
    `git checkout #{branch}`

    # check if checkout succeeded
    actual_branch = `git rev-parse --abbrev-ref HEAD`

    return actual_branch.chomp! == branch
  end

  def GithubApi.DoesBranchExist remote,  branch
    puts "Checking if branch #{branch} existing at #{remote}..."
    `git ls-remote --heads #{remote} #{branch}`
  end

  def GithubApi.RebaseLocal branch
    puts "Rebasing #{branch} with checked out branch..."
    `git stash`
    `git rebase #{branch}`
  end

  def GithubApi.CheckoutLocal branch
    puts "Checking out local branch: #{branch}..."
    `git checkout #{branch}`
  end

  # Reverts commits from commit_hashes, expected order is newest to oldest
  def GithubApi.RevertLocal branch, commit_hashes
    puts "Reverting commits on local branch: #{branch}..."
    `git checkout #{branch}`
    recent_hash = commit_hashes[0]
    past_hash = commit_hashes[-1]
    `git --no-edit revert #{past_hash}^..#{recent_hash}`
  end

  def GithubApi.TagLocal commit_hash, tag_name, message
    puts "Tagging commit hash: #{commit_hash} with #{tag_name}..."
    `git tag -a #{tag_name} #{commit_hash} -m #{message}`
  end

  def GithubApi.GetRecentCommitHash branch
    git_log_raw = `git log -1 #{branch}`
    return GithubApi.GetCommitHashesFromLog(git_log_raw).first
  end

  def GithubApi.ShowCommitInfoLocal commit_hash
    `git show --name-only #{commit_hash}`
  end

  def GithubApi.ForcePushBranch remote, branch
    # use url substituted with un/pwd
    #remote_url = GithubApi.InsertCredsInRemote remote
    puts "Force Pushing #{branch} to #{remote}..."
    `git push #{remote} #{branch} -f`
  end

  def GithubApi.InsertCredsInRemote remote_name
    url = `git config --get remote.#{remote_name}.url`
    url = GithubApi.InsertCredsInUrl(url) if !url.include? '@'
    url
  end

  def GithubApi.InsertCredsInUrl url
    url = url.sub('http://', "http://#{ENV['un']}:#{ENV['pwd']}@")
    url
  end

  def GithubApi.PushBranch remote, branch
    #remote_url = GithubApi.InsertCredsInRemote remote
    puts "Pushing #{branch} to #{remote}..."
    `git push #{remote} #{branch}`
  end

  def GithubApi.HaveLocalChanges
    `git status -s`
  end

  def GithubApi.DeleteLocalBranch branch
    `git branch -D #{branch}`
  end

  def GithubApi.DeleteRemoteBranch remote, branch
    status = GithubApi.DoesBranchExist remote, branch
    `git push #{remote} :#{branch}` if status.chomp! == GlobalConstants::EMPTY
  end

  def GithubApi.PullWithRebase remote, branch
    `git pull --rebase #{@repo_url} #{@branch}`
  end

  def GithubApi.CommitAllLocalAndPush comment

    `git add .`

    status = `git commit -m "#{comment}"`
    return false if status != GlobalConstants::EMPTY

    #todo: ensure push defaults are set up
    status = `git push`
    return status != GlobalConstants::EMPTY

  end

  def GithubApi.CommitChanges comment
    git_status = GithubApi.HaveLocalChanges
    if git_status != GlobalConstants::EMPTY
      puts 'Going to add changes to git index...'
      #gotcha: line breaks need to be in double-quotes
      val = git_status.split("\n")
      val.each { |x|
      puts "#{x}"
        value = x.split(' M ').last || x.split('?? ').last
        if (/.csproj/.match(value) || /packages.config/.match(value) || /.semver/.match(value))
          status = `git add #{value}`
          if status != GlobalConstants::EMPTY
            return false
          end
        end
      }
    end
  
    puts 'Going to commit changes...'
    status = `git commit -m "#{comment}"`
    return status != GlobalConstants::EMPTY
  end

  # Returns commits in order of newest to oldest
  def GithubApi.BranchCommitDiff base_branch, derived_branch
    puts "Getting commit diff from #{base_branch} to #{derived_branch}"
    commit_diff_raw = `git log  #{base_branch}..#{derived_branch}`
    puts commit_diff_raw

    return GithubApi.GetCommitHashesFromLog commit_diff_raw
  end

  # Returns commits in order of newest to oldest
  def GithubApi.GetCommitHashesFromLog git_log
    matches = git_log.scan /^commit [a-zA-Z0-9]*$/
    commit_len = 'commit '.length
    commit_hashes = matches.map { |v| v[commit_len, v.length-1] }
    return commit_hashes
  end


  # we do NOT want to switch to parent folder but stay in current repo dir when we exit this method
  def GithubApi.CheckoutRepoAfresh repo_url, branch

    repo = GithubApi.ProjectNameFromRepo repo_url
    return false if repo == GlobalConstants::EMPTY

    # clear repo folder if it already exists
    if File.directory? repo
      puts 'Repository already exists! Cleaning...'
      FileUtils.rm_rf repo
    end

    #repo_url = GithubApi.InsertCredsInUrl repo_url
    # clone to local
    puts 'Cloning repo to local...'
    begin
      # also tests for valid repo, this will cout if cmd fails, no need for additional message
      cmd_out = system "git clone #{repo_url}"
      return false if cmd_out.to_s == 'false'
    rescue
      puts "Clone repo for #{repo_url} failed"
      puts $!
      return false
    end

    # checkout requested branch if it's not the default branch checked out when cloned
    Dir.chdir repo
    puts "Checking out requested branch: #{branch}"
    `git fetch`

    cmd_out = GithubApi.CheckoutExistingBranch branch

    return cmd_out
  end

  def GithubApi.ProjectNameFromRepo repo_url
    puts "Repo Url provided: #{repo_url}. Parsing..."
    repo = GlobalConstants::EMPTY
    begin
      uri = Addressable::URI.parse repo_url
    rescue
      puts $!
      puts "repo_url: #{repo_url} parse failed"
      return repo
    end

    if uri.nil?
      puts 'Invalid repo_url provided'
      return repo
    end

    directory = Pathname.new(uri.path).basename
    if directory.nil?
      puts 'No directory provided in repo_url'
      return repo
    end

    repo = directory.to_s.gsub uri.extname, repo
    puts "Repository name parsed: #{repo}"

    repo
  end

  def GithubApi.SetPushDefaultSimple
    `git config --global push.default simple`
  end
end
