class InputValidator

  def initialize
    @simple_validator = SimpleValidator.new
  end

  def test_mode
    @test_mode = true
  end

  # We should do more specific test of which environment variables are we expecting or which metatdata are we expecting
  #if project publishes nuget we need to check if major /minor/patch incrmeented but not all 3

  def validate_version_map version_map
    if version_map.nil? || !version_map.is_a?(GlobalConstants::HASH)
      yield 'Version map must be a non-empty ' + GlobalConstants::HASH
    end
  end

  def validate_manifest m

    manifest = Hashit.new m
    puts 'Validating upgrade manifest...'

    if manifest.nil? || manifest.class.to_s != 'Hashit'
      yield 'Config map must be a non-nil class of type Hashit'
    end

    @node_name = 'manifest'
    yield @simple_validator.method_exists manifest, 'version_source'
    yield @simple_validator.method_value_not_nil manifest, 'version_source'
    yield @simple_validator.method_exists manifest.version_source, 'repo_url'
    yield @simple_validator.method_value_not_nil_or_empty manifest.version_source, 'repo_url'
    yield @simple_validator.method_exists manifest.version_source, 'branch'
    yield @simple_validator.method_value_not_nil_or_empty manifest.version_source, 'branch'
    yield @simple_validator.method_exists manifest, 'projects'
    yield @simple_validator.method_value_not_nil manifest, 'projects'
  end

  def validate_project_node project

    @node_name = 'project'

    # ensure is_root value's boolean only if the key exists
    msg = @simple_validator.method_exists project, 'is_root'
    if msg.nil?
      msg = @simple_validator.method_value_not_nil_or_empty project, 'is_root'
      project.is_root = project.is_root.downcase == 'y' if msg.nil?
    else
      yield msg
    end

    # previous and next keys are required, their values are not
    yield @simple_validator.method_exists project, 'next'
    yield @simple_validator.method_exists project, 'previous'

    @node_name = 'project.metadata'
    yield @simple_validator.method_exists project.metadata, 'repo_url'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'repo_url'

    yield @simple_validator.method_exists project.metadata, 'branch'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'branch'

    yield @simple_validator.method_exists project.metadata, 'should_upgrade'
    msg = @simple_validator.method_value_not_nil_or_empty project.metadata, 'should_upgrade'
    project.metadata.should_upgrade = project.metadata.should_upgrade.downcase == 'y' if msg.nil?
    yield msg

    yield @simple_validator.method_exists project.metadata, 'should_publish_nuget'
    msg = @simple_validator.method_value_not_nil_or_empty project.metadata, 'should_publish_nuget'
    project.metadata.should_publish_nuget = project.metadata.should_publish_nuget.downcase == 'y' if msg.nil?
    yield msg

    yield @simple_validator.method_exists project.metadata, 'env_vars'
    yield @simple_validator.method_value_not_nil project.metadata, 'env_vars'

    yield @simple_validator.method_exists project.metadata, 'status'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata, 'status'

    yield @simple_validator.method_exists project.metadata, 'build_configuration_id'
    yield @simple_validator.method_exists project.metadata, 'build_wait_time_in_secs'

    @node_name = 'project.metadata.env_vars'
    yield @simple_validator.method_exists project.metadata.env_vars, 'env'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'env'

    yield @simple_validator.method_exists project.metadata.env_vars, 'service_name'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'service_name'

    if !@test_mode
      yield @simple_validator.method_exists project.metadata.env_vars, 'AI_InstrumentationKey'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'AI_InstrumentationKey'

      yield @simple_validator.method_exists project.metadata.env_vars, 'AppClientId'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'AppClientId'

      yield @simple_validator.method_exists project.metadata.env_vars, 'RuntimePath'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'RuntimePath'

      yield @simple_validator.method_exists project.metadata.env_vars, 'SettingsAccount'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'SettingsAccount'

      yield @simple_validator.method_exists project.metadata.env_vars, 'SettingsAccountKey'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'SettingsAccountKey'

      yield @simple_validator.method_exists project.metadata.env_vars, 'unitestconnectionString'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'unitestconnectionString'

      yield @simple_validator.method_exists project.metadata.env_vars, 'should_update_settings_connstr'
      yield @simple_validator.method_value_not_nil_or_empty project.metadata.env_vars, 'should_update_settings_connstr'
    end

    @node_name = 'project.metadata.semver'
    yield @simple_validator.method_exists project.metadata, 'semver'
    yield @simple_validator.method_value_not_nil project.metadata, 'semver'
    yield @simple_validator.method_exists project.metadata.semver, 'file'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata.semver, 'file'

    yield @simple_validator.method_exists project.metadata.semver, 'dimension'
    yield @simple_validator.method_value_not_nil_or_empty project.metadata.semver, 'dimension'

    # location key required not value
    yield @simple_validator.method_exists project.metadata.semver, 'location'

  end

end



# nil return is treated as no error
class SimpleValidator

  CANNOT_CONTINUE = '. Cannot continue!'
  IS_MISSING = ' is missing'

  def method_exists object, method
    begin
      if !object.respond_to? method
        "#{@node_name}\'s method: *#{method}*" + IS_MISSING
      end
    rescue
      nil
    end
  end

  def method_value_not_nil_or_empty object, method
    begin
      value = object.send method
      if value.nil? || value.to_s.strip.length == 0
        "#{@node_name}\'s *#{method}* value is empty or" + IS_MISSING
      end
    rescue
      nil
    end
  end

  def method_value_not_nil object, method
    begin
      value = object.send method
      if value.nil?
        "#{@node_name}\'s *#{method}* value" + IS_MISSING
      end
    rescue
      nil
    end
  end
  
end
