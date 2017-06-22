=begin

Uses project dependency map and configuration to process a DataPlatform Service's 
code repository level framework upgrade and service deployments

=end

class UpgradeAll

  VERSION_MAP_FILE = 'versionmap.json'
  # todo: remove the up one level path
  MANIFEST_FILE = 'manifest.json'

  # repo_url is where the last known version map and manifest are checked-in
  def initialize repo_url, branch, manifest_path = MANIFEST_FILE

    @repo_url = repo_url
    @branch = branch
    @manifest_path = manifest_path
    @manifest = JSON.parse File.read(@manifest_path) if File.exist? @manifest_path

  end

  def manifest
    @manifest
  end

  def version_map
    @version_map
  end

  def retrieve_artifacts
    return if !GithubApi.CheckoutRepoAfresh @repo_url, @branch

    # JSON files converted to hash
    @version_map = JSON.parse File.read(VERSION_MAP_FILE) if File.exist? VERSION_MAP_FILE
    @manifest = JSON.parse File.read(@manifest_path) if File.exist? @manifest_path

    Dir.chdir GlobalConstants::PARENTDIR
  end

  def Do input_validator, is_local_run = false

    GithubApi.SetPushDefaultSimple

    puts "\n"
    puts GlobalConstants::UPGRADE_PROGRESS + 'Upgrade All has begun..'

    # retrieve version map and upgrade manifest
    puts GlobalConstants::UPGRADE_PROGRESS + 'Retrieving artifacts...'
    retrieve_artifacts

    return false if @version_map.nil? || @manifest.nil?

    #find version diff. If no changes exist, kick off deploy cycle only
    puts GlobalConstants::UPGRADE_PROGRESS + 'Calculating version diff...'
    versions_to_update = version_diff

    # nothing to update
    if versions_to_update.nil? || versions_to_update.length == 0
      puts 'No version diff, nothing to upgrade!'
      return true
    end

    # validate manifest
    puts GlobalConstants::UPGRADE_PROGRESS + 'Validating manifest...'
    validation_errors = []
    input_validator.validate_manifest(@manifest) do |error|
      validation_errors << error if !error.nil?
    end
    raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

    nuget_targets = nuget_targets_in_env_if_any 'checkoutdir.txt'
    upgrader = Upgrade.new versions_to_update

    # if changes exist, cycle through dependency tree and kick off upgrades
    puts GlobalConstants::UPGRADE_PROGRESS + 'Navigating projects...'
    dep_tree = DependencyTree.new(@manifest['projects'])
    dep_tree.traverse do |node|

      next if !check_should_upgrade node
      next if check_success_state node

      puts GlobalConstants::UPGRADE_PROGRESS + " Processing project #{node.project_name}..."

      # validate project node
      puts GlobalConstants::UPGRADE_PROGRESS + 'Validating project node...'
      input_validator.validate_project_node(node) do |error|
        validation_errors << error if !error.nil?
      end
      raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

      # the upgrade
      puts GlobalConstants::UPGRADE_PROGRESS + " Upgrading project #{node.project_name}..."
      upgrade_status = upgrader.Do node, nuget_targets, is_local_run

      # save node name to use for status update
      node_name = node._node_name

      # set project status in json
      if upgrade_status
        puts GlobalConstants::UPGRADE_PROGRESS + " Upgrade of #{node.project_name} succeeded"
        @manifest['projects'][node_name]['metadata']['status'] = GlobalConstants::SUCCESS
        Dir.chdir GlobalConstants::PARENTDIR

        # if publishing nuget package, wait for a minute for publish to finish
        waitfor node.metadata.build_wait_time_in_secs if node.metadata.should_publish_nuget
      else
        # either cycle was unterrupted, a step in upgrade failed or full cycle successfully completed
        # save the version map and manifest
        puts GlobalConstants::UPGRADE_PROGRESS + " Upgrade of #{node.project_name} failed"
        @manifest['projects'][node_name]['metadata']['status'] = GlobalConstants::FAILED
        save_version_manifest versions_to_update if !is_local_run
        # no more processing after failure
        return false
      end

    end

    # upgrade completed successfully, update status as unprocessed and save version map and manifest, push
    reset_status_unprocessed

    save_version_manifest versions_to_update if !is_local_run

    true
  end

=begin
  When running in a local upgrade scenario, nuget targets may be supplied via either 
  1. a path in file
  2. environment variable
=end
  def nuget_targets_in_env_if_any checkout_file_path = ''
    existing_targets = nil
    if File.exist? checkout_file_path
      existing_targets = (File.read checkout_file_path) + '/build_artifacts'
    elsif !ENV[GlobalConstants::NUGET_TARGETS].nil? && ENV[GlobalConstants::NUGET_TARGETS].strip != GlobalConstants::EMPTY
      existing_targets = ENV[GlobalConstants::NUGET_TARGETS]
    end
    target_list = []
    target_list = existing_targets.split(',') if !existing_targets.nil?
    target_list
  end

  def check_should_upgrade node
    status = node.metadata.should_upgrade
    puts GlobalConstants::UPGRADE_PROGRESS + " Skipping upgrade for project #{node.project_name}..." if !status
    status
  end

  def check_success_state node
    status = node.metadata.status == GlobalConstants::SUCCESS
    puts GlobalConstants::UPGRADE_PROGRESS + " Project #{node.project_name} already in #{GlobalConstants::SUCCESS} state. Skipping upgrade..." if status
    status
  end

  def save_version_manifest versions_to_update

    # cd to directory where versions/manifest is present
    repo_folder = GithubApi.ProjectNameFromRepo @repo_url
    Dir.chdir repo_folder

    # update files
    File.open(@manifest_path, 'w') do |f|
      f.write @manifest.to_json
    end

    # merge updated versions with known version map
    @version_map = @version_map.merge versions_to_update
    File.open(VERSION_MAP_FILE, 'w') do |f|
      f.write @version_map.to_json
    end

    # save branch
    GithubApi.CommitAllLocalAndPush 'Updated manifest and version map'

  end

  def version_diff

    # create version map afresh to compare
    vm = VersionMap.new
    version_repo_url = @manifest['version_source']['repo_url']
    versions = vm.version_map version_repo_url, @manifest['version_source']['branch']

    # If remote version doesn't exist, save it
    if @version_map.nil?
      File.write VERSION_MAP_FILE, versions.to_json
      GithubApi.PushBranch @repo_url, @branch

      return hash
    end

    # compare current and remote versions, obtain changeset
    hash = Hash[*(versions.to_a - @version_map.to_a).flatten]

    # return changeset hash
    hash
  end

  def reset_status_unprocessed
    @manifest['projects'].each { |proj|
      proj.each { |item|
        item['metadata']['status'] = GlobalConstants::UNPROCESSED if item.class.to_s != 'String'
      }
    }
    @manifest
  end

  def validation_error_message validation_errors
    "One or more validation errors have occurred: #{validation_errors.join(' ')}"
  end

  def waitfor build_wait_time_in_secs
    checks = 0
    build_wait_time_in_secs = build_wait_time_in_secs.to_i

    wait_secs = 5
    until checks > build_wait_time_in_secs
      sleep wait_secs
      checks += wait_secs
      puts GlobalConstants::UPGRADE_PROGRESS + "Waiting for #{wait_secs} seconds..."
    end
  end

end
