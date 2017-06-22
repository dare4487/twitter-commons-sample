=begin

Processes upgrade for a C# code repositoryy

=end

class Upgrade

  UPGRADE_BRANCH = 'upgrade'
  BACKUP_BRANCH = 'upgradeBackupDoNotDelete'
  VERSION_UPGRADE_COMMIT = 'Versions updated'
  VERSION_UPGRADE_FAIL_BUILD_COMMIT = 'Versions updated, build failed'

  def initialize versions, rollback=false
    @versions = versions
    @rollback = rollback
  end

  def checkout_upgrade_branch

    # obtain an upgrade branch
    if (GithubApi.DoesBranchExist('origin', UPGRADE_BRANCH) != GlobalConstants::EMPTY)
      puts 'Checking out existing upgrade branch...'
      return false if !GithubApi.CheckoutExistingBranch(UPGRADE_BRANCH) == GlobalConstants::EMPTY
    else
      puts 'Checking out new upgrade branch...'
      return false if !GithubApi.CheckoutNewBranch(UPGRADE_BRANCH) == GlobalConstants::EMPTY
    end

    return true
  end

  def create_upgrade_tag
    versioning = SemverVersioning.new
    semver_file = @config_map.metadata.semver.file
    if @config_map.metadata.should_publish_nuget && semver_file != nil && semver_file != GlobalConstants::EMPTY
      semver_file.capitalize
      ver_tag = versioning.get_current_version @config_map.metadata.semver.location, semver_file
      return "upgrade-#{ver_tag}"
    else
      utc_now = DateTime.now.utc
      date_tag = utc_now.strftime(DATE_FORMAT)
      return "upgrade-#{date_tag}"
    end
  end

  def Do config_map, nuget_targets, is_local_run=false

    @config_map = config_map
    @repo_url = @config_map.metadata.repo_url
    @branch = @config_map.metadata.branch

    # checkout repo and branch
    return false if !GithubApi.CheckoutRepoAfresh @repo_url, @branch

    tag_creator = method(:create_upgrade_tag)

    # TODO: Need to check if node has failed before invoking rollback
    if @rollback
      puts "Starting Rollback..."
      rollback = new Rollback @repo_url, 'origin', @branch, BACKUP_BRANCH, @config_map.metadata
      tag_creator = rollback.method(:create_rollback_tag)
      return false if !rollback.Do
    end

    # When upgrade branch exists we are coming from some failure state and dont need to backup the branch again
    if (GithubApi.DoesBranchExist('origin', UPGRADE_BRANCH) == GlobalConstants::EMPTY)
      GithubApi.CreateNewBranch(BACKUP_BRANCH, @branch)
      GithubApi.ForcePushBranch('origin', BACKUP_BRANCH)
    end

    # make upgrade branch
    return false if !checkout_upgrade_branch

    # use local nuget path for restore if provided
    set_local_nuget_target nuget_targets

    # replace versions in package config files
    puts GlobalConstants::UPGRADE_PROGRESS + 'Replacing package versions...'
    pkg_files = Dir.glob '**/packages.config'
    if !replace_package_versions(pkg_files)
      puts GlobalConstants::UPGRADE_PROGRESS + 'Package version replacement failed.'
      return false
    end

    # replace versions in project references
    puts GlobalConstants::UPGRADE_PROGRESS + 'Replacing project versions...'
    proj_files = Dir.glob '**/*.csproj'
    if !replace_project_versions(proj_files)
      puts GlobalConstants::UPGRADE_PROGRESS + 'Project version replacement failed.'
      return false
    end

    # Check in manifest if project publish nuget? If yes, increment .semver
    # QUESTION: Should this method increment semver even if there is no nuget published?
    puts GlobalConstants::UPGRADE_PROGRESS + 'Upgrading semver...'
    semver_inc_done = increment_semver_if_publish is_local_run
    nuget_targets << Dir.pwd + '/build_artifacts' if @config_map.metadata.should_publish_nuget

    # Tag commit
    recent_commit_hash = GithubApi.GetRecentCommitHash(@branch)
    #rollback_tag = tag_creator.call()

    #GithubApi.TagLocal(recent_commit_hash, rollback_tag, "Autoupgrade Tag")

    # do rake build to test for compilation errors. This needs ENV vars set, passed in via config
    set_project_env_vars @config_map.metadata.env_vars
    output = system 'rake'
    if output.to_s == 'false'
      puts GlobalConstants::UPGRADE_PROGRESS + ' Rake Error: There were errors during rake run.'
      # save state
      GithubApi.CommitChanges( VERSION_UPGRADE_FAIL_BUILD_COMMIT)
      clear_project_env_vars

      return false
    end
    clear_project_env_vars

    # update version map with nuget versions after build success
    if semver_inc_done
      nuget_versions = update_version_map '/build_artifacts/*.nupkg'
      @versions.merge! nuget_versions
      puts GlobalConstants::UPGRADE_PROGRESS + 'Semver upgraded. Version map updated.'
    end

    if is_local_run
      puts GlobalConstants::UPGRADE_PROGRESS + 'Local run. No branch update or teamcity build triggered'
    else
      puts GlobalConstants::UPGRADE_PROGRESS + 'Branch update in progress...'
      return false if !update_branch
      # kick off teamcity build
      puts GlobalConstants::UPGRADE_PROGRESS + 'Teamcity Project being triggered...'
      TeamCityApi.trigger_build @config_map.metadata.build_configuration_id, ENV['tc_un'], ENV['tc_pwd']
    end

    true
  end

  def set_local_nuget_target nuget_targets
    num_paths = 1;
    nuget_targets.each { |target|
      nuget_targets_file = Dir.pwd + '/src/.nuget/Nuget.Config'
      doc = Nokogiri::XML(File.read nuget_targets_file)
      node_parent = doc.at_css 'packageSources'
      node = Nokogiri::XML::Node.new('add', doc)
      node['key'] = "local_nuget_source#{num_paths}"
      node['value'] = target
      node_parent.add_child node
      File.write nuget_targets_file, doc.to_xml
      num_paths  += 1
    }
  end

  def update_branch

    # see if any files changed and commit
    git_status = GithubApi.HaveLocalChanges
    git_status = git_status != nil || git_status != GlobalConstants::EMPTY

    puts GlobalConstants::UPGRADE_PROGRESS + "Local changes are present: #{git_status}"
    if git_status
      puts GlobalConstants::UPGRADE_PROGRESS + 'Local version changes are being committed'
      return false if !GithubApi.CommitChanges('Versions updated')
    end

    # rebase and push the branch
    puts GlobalConstants::UPGRADE_PROGRESS + 'Rebasing and pushing update branch...'
    GithubApi.CheckoutLocal @branch
    GithubApi.RebaseLocal UPGRADE_BRANCH

    # if push fails, do a pull --rebase of the branch and fail the upgrade.
    # Upstream commits need to accounted for and full upgrade cycle must be triggered
    # Build failure email will inform concerned team
    git_status = GithubApi.PushBranch(@repo_url, @branch) == GlobalConstants::EMPTY
    if git_status
      puts GlobalConstants::UPGRADE_PROGRESS + "Version upgrade changes have been rebased with #{@repo_url}/#{@branch} and pushed"
    else
      GithubApi.PullWithRebase @repo_url, @branch
      GithubApi.PushBranch @repo_url, @branch
      puts GlobalConstants::UPGRADE_PROGRESS + "Push after version upgrade failed for #{@repo_url}/#{@branch}. Pull with rebase done and pushed"
      return false
    end

    # delete upgrade branch both local and remote
    GithubApi.DeleteLocalBranch UPGRADE_BRANCH
    GithubApi.DeleteRemoteBranch @repo_url, UPGRADE_BRANCH

    true
  end

  def replace_package_versions pkg_files

    begin
      # iterate each package file, replace version numbers and save
      pkg_files.each{ |file|
        puts "Finding packages in: #{Dir.pwd}/#{file}..."
        doc = Nokogiri::XML File.read(file)
        nodes = doc.xpath "//*[@id]"
        nodes.each { |node|
          node['version'] = @versions[node['id']] if @versions.has_key?(node['id'])
        }
        File.write file, doc.to_xml
      }
    rescue
      puts $!
      return false
    end

    return true

  end

=begin
    Typical block of reference node change looks like:
    Before:
    <Reference Include="MassTransit, Version=3.0.0.0, Culture=neutral, PublicKeyToken=b8e0e9f2f1e657fa, processorArchitecture=MSIL">
      <HintPath>..\packages\MassTransit.3.0.14\lib\net45\MassTransit.dll</HintPath>
      <Private>True</Private>
    </Reference>
    After: (file version removed, hint path version number updated)
    <Reference Include="MassTransit">
      <HintPath>..\packages\MassTransit.3.0.15\lib\net45\MassTransit.dll</HintPath>
      <Private>True</Private>
    </Reference>
=end
  def replace_project_versions proj_files

    begin
      # iterate each package file, replace version numbers and save
      proj_files.each{ |file|
        puts "Updating references in: #{file}..."
        doc = Nokogiri::XML File.read file
        nodes = doc.search 'Reference'
        nodes.each { |node|
          ref_val = node['Include']
          # grab  the identifier
          id = ref_val.split(',')[0]
          # clean out file version
          node['Include'] = id

          # replace version in hint path
          hint_path = node.search 'HintPath'
          if hint_path && hint_path[0] != nil
            hint_path_value = hint_path[0].children.to_s
            # this identifier is not the same as the node['Include'] one.
            # For ex., Runtime, Core and Storage assemblies will be referred to from within other packages like Management, Test etc
            hint_path_id = id_from_hint_path hint_path_value
            if @versions.has_key? hint_path_id
              hint_path_parts = hint_path_value.split '\\'
              hint_path_parts[2] = hint_path_id + GlobalConstants::DOT + @versions[hint_path_id]
              hint_path[0].children = hint_path_parts.join '\\'
            end
          end
        }
        File.write file, doc.to_xml
      }
    rescue
      puts $!
      return false
    end

    return true

  end

  def id_from_hint_path path
    name = path.split('\\')[2].split GlobalConstants::DOT
    name_without_ver = GlobalConstants::EMPTY
    name.all? {|i|
      name_without_ver += i.to_s + GlobalConstants::DOT if i.to_i == 0
    }
    name_without_ver.chomp GlobalConstants::DOT
  end

  def set_project_env_vars envs
    ENV['AI_InstrumentationKey'] = envs.AI_InstrumentationKey if envs.respond_to? 'AI_InstrumentationKey'
    ENV['AppClientId'] = envs.AppClientId if envs.respond_to? 'AppClientId'
    ENV['ConfigSettingsTable'] = envs.ConfigSettingsTable if envs.respond_to? 'ConfigSettingsTable'
    ENV['env'] = envs.env if envs.respond_to? 'env'
    ENV['RuntimePath'] = envs.RuntimePath if envs.respond_to? 'RuntimePath'
    ENV['ServiceName'] = envs.ServiceName if envs.respond_to? 'ServiceName'
    ENV['SettingsAccount'] = envs.SettingsAccount if envs.respond_to? 'SettingsAccount'
    ENV['SettingsAccountKey'] = envs.SettingsAccountKey if envs.respond_to? 'SettingsAccountKey'
    ENV['should_update_settings_connstr'] = envs.should_update_settings_connstr if envs.respond_to? 'should_update_settings_connstr'
    ENV['unitestconnectionString'] = envs.unitestconnectionString if envs.respond_to? 'unitestconnectionString'
  end

  def clear_project_env_vars
    ENV['AI_InstrumentationKey'] = '' if ENV.respond_to? 'AI_InstrumentationKey'
    ENV['AppClientId'] = '' if ENV.respond_to? 'AppClientId'
    ENV['ConfigSettingsTable'] = '' if ENV.respond_to? 'ConfigSettingsTable'
    ENV['env'] = '' if ENV.respond_to? 'env'
    ENV['RuntimePath'] = '' if ENV.respond_to? 'RuntimePath'
    ENV['ServiceName'] = '' if ENV.respond_to? 'ServiceName'
    ENV['SettingsAccount'] = '' if ENV.respond_to? 'SettingsAccount'
    ENV['SettingsAccountKey'] = '' if ENV.respond_to? 'SettingsAccountKey'
    ENV['should_update_settings_connstr'] = '' if ENV.respond_to? 'should_update_settings_connstr'
    ENV['unitestconnectionString'] = '' if ENV.respond_to? 'unitestconnectionString'
  end

  def increment_semver_if_publish is_local_run

    if is_local_run
      auto_update_semver @config_map.project_name, @config_map.metadata.semver.location, @config_map.metadata.semver.file, @config_map.metadata.semver.dimension
      return true
    else
      if @config_map.metadata.should_publish_nuget
        semver_file = @config_map.metadata.semver.file
        semver_file.capitalize if (semver_file != nil && semver_file != GlobalConstants::EMPTY)

        auto_update_semver @config_map.project_name, @config_map.metadata.semver.location, semver_file, @config_map.metadata.semver.dimension
        return true
      else
        puts GlobalConstants::UPGRADE_PROGRESS + 'Project does not publish nuget.'
      end
    end

    false
  end

  def update_version_map path
    path = File.join(Dir.pwd, path)
    nugets = Dir.glob path
    versions = {}
    nugets.each { |nuget|
      full_name = File.basename nuget
      full_name = full_name.sub! '.nupkg', ''
      full_name = full_name.sub! '.symbols', '' if full_name.include? '.symbols'
      dot_pos = full_name.index GlobalConstants::DOT
      nuget_name = full_name[0..dot_pos-1]
      nuget_version = full_name[dot_pos+1..full_name.length]
      versions[nuget_name] = nuget_version
    }
    versions
  end
end
