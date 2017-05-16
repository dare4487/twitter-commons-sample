module AchFilesExamples

  def well_fargo_empty_filename
    File.expand_path(File.dirname(__FILE__) + '/../examples/well_fargo_empty.ach')
  end

  def well_fargo_with_data
    File.expand_path(File.dirname(__FILE__) + '/../examples/well_fargo_with_data.ach')
  end

end

if defined?(World)
  World(AchFilesExamples)
else
  include AchFilesExamples
end