=begin
  rollback flow:

  check rollback command 
  avoid replacing backup branch 

  commit diff on backup vs current 
  at least one commit should be version upgrade 
  create revert commits on commit diff 

  tag commit with nuget version if it publishes nuget
  tag commit with timestamp if it is a service 
  
  replace backup branch   
=end



class RollbackUpgrade

  DATE_FORMAT = 'date_%m-%d-%Y_time_%H.%M.%S'

  def initialize repo_url, remote, current_branch, rollback_branch, metadata
    @repo_url = repo_url
    @remote = remote
    @current_branch = current_branch
    @rollback_branch = rollback_branch
    @metadata = metadata
  end

  def create_rollback_tag
    versioning = SemverVersioning.new
    semver_file = @config_map.metadata.semver.file
    if @config_map.metadata.should_publish_nuget && semver_file != nil && semver_file != GlobalConstants::EMPTY
      semver_file.capitalize
      ver_tag = versioning.get_current_version @config_map.metadata.semver.location, semver_file
      return "rollback-#{ver_tag}"
    else
      utc_now = DateTime.now.utc
      date_tag = utc_now.strftime(DATE_FORMAT) 
      return "rollback-#{date_tag}"
    end
  end

  def Do
    commit_hashes = GithubApi.BranchCommitDiff(@rollback_branch, @current_branch)
    if commit_hashes.length == 0
      puts `No difference between branches #{current_branch} and #{rollback_branch}, aborting rollback.`
      return false
    end

    # check hashes for version upgrade commit message
    if !commit_hashes.any?{ |c_hash| GithubApi.ShowCommitInfoLocal(c_hash).include? Upgrade::VERSION_UPGRADE_COMMIT }
      puts `No version upgrade commit detected to roll back, aborting rollback.`
      return false
    end

    GithubApi.RevertLocal(@current_branch, commit_hashes)

    puts `@<--- Rollback branch revert completed. @<---`
    return true
  end
end
