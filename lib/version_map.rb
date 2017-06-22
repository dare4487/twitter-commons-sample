=begin
    Use case #1:
    Generate and returns a unique list of all packages and their versions for a given repository
        Example: 
        10.0.0(obtained from semver) version map will look like:
        {
            "RelayHealth.DataPlatform.Framework" => {
                "Version" => "10.0.0"
                "RelayHealth.DataPlatform.Contracts" => "10.0.0",
                "Windows.Azure.Storage" => "4.3.0"
                ...
            }
        }
        When solution uses using individual package versioning, version map still like above because framework forms the root of all dependencies.
        
    This can be maintained static by parsing once and saving to a github repo or can be done realtime.
    Processing time is minimal, DP repo checkout time may actually be longer.
    
    1. Checkout repo
    2. Scan packages.config files for packages and versions and store in array
    3. Uniquefy list to a hash map and return
=end

class VersionMap

  VERSIONMAPFILE = 'versionmap.json'

  def version_map repo_url, branch
    return if repo_url.to_s.strip.length == 0
    return if branch.to_s.strip.length == 0

    return if !GithubApi.CheckoutRepoAfresh repo_url, branch

    # load old versions
    old_versions = {}
    if File.exists? VERSIONMAPFILE
      old_versions = JSON.parse File.read(VERSIONMAPFILE)
    end

    # grab all packages.config files
    versions = {}
    pkg_files = Dir.glob '**/packages.config'
    pkg_files.each{ |file|
      #puts "Finding packages in: #{file}"
      doc = Nokogiri::XML File.read(file)
      nodes = doc.xpath "//*[@id]"
      nodes.each { |node|
        puts "======Error: Package #{node['id']} with version #{node['version']} has a different pre-exisiting version: #{versions[node['id']]}" if (!versions[node['id']].nil? && node['version'] != versions[node['id']])
        versions[node['id']] = node['version']
      }
    }

    if Dir.exist? 'versioning'
      update_platform_multiple_semver_package_versions versions
    else
      update_platform_single_semver_package_versions versions
    end

    Dir.chdir GlobalConstants::PARENTDIR
    File.write VERSIONMAPFILE, versions.to_json

    versions

  end

  def update_platform_single_semver_package_versions versions
    ver = load_semver '.semver'
    v = ver.to_s.sub 'v', ''    # removes 'v' at start of string which isn't expected for version spec in .package and .csproj files
    version = v
    versions['RelayHealth.DataPlatform.Contracts'] = version
    versions['RelayHealth.DataPlatform.Framework'] = version
    versions['RelayHealth.DataPlatform.Framework.Messaging'] = version
    versions['RelayHealth.DataPlatform.Framework.Web'] = version
    versions['RelayHealth.DataPlatform.Identity'] = version
    versions['RelayHealth.DataPlatform.Management'] = version
    versions['RelayHealth.DataPlatform.Management.Tools'] = version
    versions['RelayHealth.DataPlatform.Test'] = version
    versions['RelayHealth.DataPlatform.Test.Messaging'] = version

    versions
  end

  def update_platform_multiple_semver_package_versions versions
    versions['RelayHealth.DataPlatform.Contracts'] = get_semver 'Contracts.semver'
    versions['RelayHealth.DataPlatform.Framework'] = get_semver 'Framework.semver'
    versions['RelayHealth.DataPlatform.Framework.Messaging'] = get_semver 'Framework.Messaging.semver'
    versions['RelayHealth.DataPlatform.Framework.Web'] = get_semver 'Framework.Web.semver'
    versions['RelayHealth.DataPlatform.Identity'] = get_semver 'Identity.semver'
    versions['RelayHealth.DataPlatform.Management'] = get_semver 'Management.semver'
    versions['RelayHealth.DataPlatform.Management.Tools'] = get_semver 'Management.semver'
    versions['RelayHealth.DataPlatform.Test'] = get_semver 'Test.semver'
    versions['RelayHealth.DataPlatform.Test.Messaging'] = get_semver 'Test.Messaging.semver'
    versions['RelayHealth.DataPlatform.Test.Bvt'] = get_semver 'Test.Bvt.semver'
    versions['RelayHealth.DataPlatform.Runtime'] = get_semver 'Runtime.semver'
    versions['RelayHealth.DataPlatform.Runtime.Host'] = get_semver 'Runtime.semver'

    versions
  end

  def load_semver path
    v = SemVer.new
    v.load path
    v
  end

  def get_semver semver
    ver = load_semver File.join('versioning', semver)
    # remove 'v' at start of string which isn't expected for version spec in .package and .csproj files
    v = ver.to_s.sub 'v', ''
    v
  end

end