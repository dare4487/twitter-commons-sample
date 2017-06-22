=begin
    Provides API accessors for TeamCity
=end

require 'net/http'
require 'builder'

module TeamCityApi

  def TeamCityApi.get_teamcity_creds
    file = File.open(Dir.pwd + '/spec/p.txt', 'r')
    content = file.read
    content.gsub!(/\r\n?/, "\n")
    line_num = 0
    creds = []
    content.each_line do |line|
      creds << line
    end
    creds
  end

  #Build trigger API
  def TeamCityApi.trigger_build buildConfigurationId, username, password
    puts "Triggering build configuration: #{buildConfigurationId} for #{username}..."
    configContent = create_build_trigger_config buildConfigurationId
    uri = URI.parse 'http://teamcity.relayhealth.com'
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new '/httpAuth/app/rest/buildQueue'
    request.body = configContent
    request.content_type = 'application/xml'
    request.basic_auth username, password
    response = http.request request
    puts response
  end

  def TeamCityApi.create_build_trigger_config buildConfigurationId
    xml = Builder::XmlMarkup.new :indent => 2
    xml.build{
      xml.triggeringOptions 'cleanSources' => 'true', 'rebuildAllDependencies' => 'true', 'queueAtTop' => 'true'
      xml.buildType 'id' => "#{buildConfigurationId}"
    }
  end

  #Project Get/Create API
  def TeamCityApi.get_project_by_id projectId, username, password
    uri = URI.parse "http://teamcity.relayhealth.com"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Get.new "/app/rest/projects/id:#{projectId}", {'Accept' => 'application/json'}
    request.basic_auth username, password
    response = http.request request
    # File handling will be removed and instead use Tempfile for better security
    target = open("../spec/ProjectConfigByProjectId", 'w')
    target.truncate(0)
    target.write(response.body)
    target.close
  end

  def TeamCityApi.create_new_project inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/projects", {'Accept' => 'application/json'}
    request.body = requestContent
    request.content_type = 'application/json'
    request.basic_auth username, password
    response = http.request request
    puts response.body
  end

  #VCS-Root Get/Create API
  def TeamCityApi.get_vcs_roots_by_id vcsRootId, username, password
    uri = URI.parse "http://teamcity.relayhealth.com"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Get.new "/httpAuth/app/rest/vcs-roots/id:#{vcsRootId}", {'Accept' => 'application/json'}
    request.basic_auth username, password
    response = http.request request
    # File handling will be removed and instead use Tempfile for better security
    target = open("../spec/VcsRootConfigByVcsRootId", 'w')
    target.truncate(0)
    target.write(response.body)
    target.close
  end

  def TeamCityApi.create_new_vcs_root inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/vcs-roots", {'Accept' => 'application/json'}
    request.body = requestContent
    request.content_type = 'application/json'
    request.basic_auth username, password
    response = http.request request
    puts response.body
  end

  #Build Config Get/Create API
  def TeamCityApi.get_build_configs_by_projectId projectId, username, password
    uri = URI.parse "http://teamcity.relayhealth.com"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Get.new "/app/rest/projects/id:#{projectId}/buildTypes", {'Accept' => 'application/json'}
    request.basic_auth username, password
    response = http.request request
    # File handling will be removed and instead use Tempfile for better security
    target = open("../spec/BuildConfigsByProjectId", 'w')
    target.truncate(0)
    target.write(response.body)
    target.close
  end

  def TeamCityApi.get_build_configs_by_projectId_and_build_configurationId projectId, buildConfigurationId, username, password
    uri = URI.parse "http://teamcity.relayhealth.com"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Get.new "/app/rest/projects/id:#{projectId}/buildTypes/id:#{buildConfigurationId}", {'Accept' => 'application/json'}
    request.basic_auth username, password
    response = http.request request
    # File handling will be removed and instead use Tempfile for better security
    target = open("../spec/BuildConfigByProjectAndBuildConfigurationId", 'w')
    target.truncate(0)
    target.write(response.body)
    target.close
  end

  def TeamCityApi.create_new_build_configuration projectId, inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port


    request = Net::HTTP::Post.new "/httpAuth/app/rest/projects/id:#{projectId}/buildTypes", {'Accept' => 'application/json'}
    request.body = requestContent
    request.content_type = 'application/json'
    request.basic_auth username, password
    response = http.request request
    # File handling will be removed and instead use Tempfile for better security
    target = open("../spec/CreateNewBuildConfigurationResponse", 'w')
    target.truncate(0)
    target.write(response.body)
    target.close
  end

  # Setup build configuration settings
  def TeamCityApi.set_build_configuration_setting buildConfigurationId, settingName, settingValue, username, password
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Put.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/settings/#{settingName}"
    request.body = settingValue
    request.content_type = 'text/plain'
    request.basic_auth username, password
    response = http.request request
  end

  # Setup build configuration parameters
  def TeamCityApi.set_build_configuration_parameter buildConfigurationId, parameterName, parameterValue, username, password
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Put.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/parameters/#{parameterName}"
    request.body = parameterValue
    request.content_type = 'text/plain'
    request.basic_auth username, password
    response = http.request request
  end

  # Setup build configuration Vcs-Root
  def TeamCityApi.set_build_configuration_vcs_root buildConfigurationId, vcsRootId, username, password
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/vcs-root-entries/"
    request.body = create_build_config_vcs_root_config vcsRootId
    request.content_type = 'application/xml'
    request.basic_auth username, password

    response = http.request request
  end

  def TeamCityApi.create_build_config_vcs_root_config vcsRootId
    xml = Builder::XmlMarkup.new :indent => 2
    xml.tag!("vcs-root-entry"){
      xml.tag!("vcs-root", "id" => "#{vcsRootId}")
    }
  end

  # Setup build configuration step
  def TeamCityApi.set_build_configuration_build_step buildConfigurationId, inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/steps/"
    request.body = requestContent
    request.content_type = 'application/xml'
    request.basic_auth username, password
    response = http.request request
  end

  # Setup build feature step
  def TeamCityApi.set_build_configuration_feature buildConfigurationId, inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/features/"
    request.body = requestContent
    request.content_type = 'application/xml'
    request.basic_auth username, password
    response = http.request request
  end

  # Setup build trigger step
  def TeamCityApi.set_build_configuration_trigger buildConfigurationId, inputFile, username, password
    file = File.open("../spec/#{inputFile}", "r")
    requestContent = file.read
    uri = URI.parse "http://localhost:9999/"
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new "/httpAuth/app/rest/buildTypes/id:#{buildConfigurationId}/triggers/"
    request.body = requestContent
    request.content_type = 'application/xml'
    request.basic_auth username, password
    response = http.request request
  end

  def TeamCityApi.get_build_status projectId
    # list queued builds per project
    uri = URI.parse 'http://teamcity.relayhealth.com'
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Get.new "/app/rest/buildQueue?locator=project:#{projectId}", {'Accept' => 'application/json'}
    creds = TeamCityApi.get_teamcity_creds
    request.basic_auth creds[0].delete("\n"), creds[1].delete("\n")
    response = http.request request
  end

end

=begin
    creds = TeamCityApi.get_teamcity_creds
    configContent = create_build_trigger_config buildConfigurationId
    uri = URI.parse 'http://teamcity.relayhealth.com'
    http = Net::HTTP.new uri.host, uri.port
    request = Net::HTTP::Post.new '/httpAuth/app/rest/buildQueue'
    request.body = configContent
    request.content_type = 'application/xml'
    request.basic_auth creds[0].delete("\n"), creds[1].delete("\n")
    response = http.request request
    p response.body
  end
=end
# Sample Usage
#TeamCityApi.trigger_build("DataPlatform_DataPlatformOntology_ADevelopBuildDataPlatformOntology_2", "username", "password")


#TeamCityApi.get_build_configs_by_projectId "DataPlatform_DataPlatformOntology", "username", "password"
#TeamCityApi.get_build_configs_by_projectId_and_build_configurationId "DataPlatform_DataPlatformOntology", "DataPlatform_DataPlatformOntology_ADevelopBuildDataPlatformOntology_2", "username", "password"

#TeamCityApi.get_project_by_id "DataPlatform_DataPlatformOntology", "username", "password"
#TeamCityApi.create_new_project "CreateNewProjectJsonSample", "username", "password"
#TeamCityApi.get_vcs_roots_by_id "DataPlatform_DataPlatformOntology_HttpNdhaxpgit01mckessonComCarnegieRelayHealthD", "username", "password"
#TeamCityApi.create_new_vcs_root "CreateNewVcsRoot", "username", "password"
#TeamCityApi.create_new_build_configuration "DataPlatform_DataPlatformOntology", "CreateNewBuildConfiguration", "username", "username"
#TeamCityApi.set_build_configuration_setting "DataPlatform_DataPlatformOntology_DevelopBuild", "checkoutMode", "ON_AGENT", "username", "password"
#TeamCityApi.set_build_configuration_parameter "DataPlatform_DataPlatformOntology_DevelopBuild", "env.StorageAccount", "mccadpatsettings", "username", "password"
#TeamCityApi.set_build_configuration_vcs_root "DataPlatform_DataPlatformOntology_DevelopBuild", "DataPlatform_DataPlatformOntology_HttpNdhaxpgit01mckessonComPrajwalSainiRelayHea", "username", "password"
#TeamCityApi.set_build_configuration_build_step "DataPlatform_DataPlatformOntology_DevelopBuild", "RakeBuildStep", "username", "password"
#TeamCityApi.set_build_configuration_feature "DataPlatform_DataPlatformOntology_DevelopBuild", "BuildConfigurationFeature", "username", "password"
#TeamCityApi.set_build_configuration_feature "DataPlatform_DataPlatformOntology_DevelopBuild", "BuildConfigurationFeatureForFailureCondition", "username", "password"
#TeamCityApi.set_build_configuration_trigger "DataPlatform_DataPlatformOntology_DevelopBuild", "SetupTriggerForBuildStep", "username", "password"
