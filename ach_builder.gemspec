# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ach/version"

Gem::Specification.new do |s|
  s.name        = "ach_builder"
  s.version     = ACH::VERSION
  s.authors     = ["TMX Credit", "Artem Kuzko", "Sergey Potapov"]
  s.email       = ["rubygems@tmxcredit.com", "AKuzko@sphereconsultinginc.com", "blake131313@gmail.com"]
  s.homepage    = "https://github.com/TMXCredit/ach_builder"
  s.summary     = "Ruby tools for building ACH files"
  s.description = "Ruby tools for building ACH (Automated Clearing House) files"

  #s.rubyforge_project = "ach_builder"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.licenses      = ['MIT']

  s.add_development_dependency "rspec"    , ">= 2.0.0"
  s.add_runtime_dependency "activesupport", ">= 2.3.0"

  # Necessary for active_support/inflector:
  s.add_runtime_dependency "i18n"
end
