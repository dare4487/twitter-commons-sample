
class ProgetApi
  def is_package_published packageName, packageVersion, timeout
    packageLocationUri = "http://nuget2.relayhealth.com/nuget/Carnegie/Packages(Id='#{packageName}',Version='#{packageVersion}')"
    counter = timeout
    i = 0
    found = false;

    while i < counter
      response = Net::HTTP.get_response(URI packageLocationUri)
      xmldoc = Nokogiri::XML response.body
      entry = xmldoc.css "entry id"
      if entry.to_s.include? packageLocationUri
        puts "Found #{packageName}-#{packageVersion}"
        found = true
        break
      end
      sleep 1
      i += 1
    end

    puts "Not found #{packageName}-#{packageVersion}" if !found

    found
  end
end

# Sample Usage
# a = is_package_published("RelayHealth.DataPlatform.Framework", "24.5.12", 60)
# puts a
