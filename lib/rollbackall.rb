=begin

Uses project dependency map and configuration to process a DataPlatform Service's 
code repository level framework upgrade and service deployments

=end

class RollbackAll

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
    @remote_version_map
  end

  def retrieve_artifacts

    return if !GithubApi.CheckoutRepoAfresh @repo_url, @branch

    # JSON files converted to hash
    @remote_version_map = JSON.parse File.read(VERSION_MAP_FILE) if File.exist? VERSION_MAP_FILE
    @manifest = JSON.parse File.read(@manifest_path) if File.exist? @manifest_path

    Dir.chdir GlobalConstants::PARENTDIR
  end

  def version_exists

    # create version map afresh to compare
    vm = VersionMap.new
    version_repo_url = @manifest['version_source']['repo_url']
    versions = vm.version_map version_repo_url, @manifest['version_source']['branch']

    # If remote version doesn't exist, save it
    if @remote_version_map.nil?
      File.write VERSIONMAPFILE, versions.to_json
      GithubApi.PushBranch @repo_url, @branch

      return hash
    end
  end

  def Do input_validator, is_local_run=false

    puts "\n"
    puts GlobalConstants::UPGRADE_PROGRESS + 'Rollback All has begun..'

    # retrieve version map and upgrade manifest
    puts GlobalConstants::UPGRADE_PROGRESS + 'Retrieving artifacts...'
    retrieve_artifacts

    return false if @remote_version_map.nil? || @manifest.nil?

    puts GlobalConstants::UPGRADE_PROGRESS + 'Ensuring version map exists...'
    version_exists


    # validate manifest
    puts GlobalConstants::UPGRADE_PROGRESS + 'Validating manifest...'
    validation_errors = []
    input_validator.validate_manifest(@manifest) do |error|
      validation_errors << error if !error.nil?
    end
    raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

    nuget_targets = []

    # TODO: This validation could probably go in an input validator specifically for rollback
    rollback_config = @manifest['is_rollback'].IsRollback
    rollback = !rollback_config.nil? and rollback_config.downcase == 'y'
    if !rollback
      puts 'IsRollback not set in manifest, aborting rollback.'
      return false
    end
    upgrader = Upgrade.new versions_to_update, rollback

    # if changes exist, cycle through dependency tree and kick off upgrades
    puts GlobalConstants::UPGRADE_PROGRESS + 'Navigating projects...'
    dep_tree = DependencyTree.new(@manifest['projects'])
    dep_tree.traverse do |node|

      if node.metadata.should_upgrade
        puts "#{GlobalConstants::UPGRADE_PROGRESS} Processing project #{node.project_name}..."

        # validate project node
        puts GlobalConstants::UPGRADE_PROGRESS + 'Validating project node...'
        input_validator.validate_project_node(node) do |error|
          validation_errors << error if !error.nil?
        end
        raise StandardError, validation_error_message(validation_errors) if validation_errors.length > 0

        # the upgrade
        puts "#{GlobalConstants::UPGRADE_PROGRESS} Rolling back project #{node.project_name}..."
        upgrade_status = upgrader.Do node, nuget_targets, is_local_run

        # save node name to use for status update
        node_name = node._node_name

        # project status set in json
        if upgrade_status
          puts "#{GlobalConstants::UPGRADE_PROGRESS} Rollback of #{node.project_name} succeeded"
          @manifest['projects'][node_name]['metadata']['status'] = GlobalConstants::SUCCESS
          Dir.chdir GlobalConstants::PARENTDIR
        else
          # either cycle was unterrupted, a step in upgrade failed or full cycle successfully completed
          # save the version map and manifest
          puts "#{GlobalConstants::UPGRADE_PROGRESS} Rollback of #{node.project_name} failed"
          @manifest['projects'][node_name]['metadata']['status'] = GlobalConstants::FAILED
          # no more processing after failure
          return false
        end

      else
        puts "#{GlobalConstants::UPGRADE_PROGRESS} Skipping Rollback for project #{node.project_name}..."
      end
    end

    # upgrade completed successfully, set rollback to 'n' state, update status as unprocessed and save version map and manifest, push
    @manifest['is_rollback'] = 'n'
    reset_status_unprocessed


    true
  end

  def save version_manifest

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

end
