# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flat_map/version"

Gem::Specification.new do |s|
  s.name        = "HornsAndHooves-flat_map"
  s.version     = FlatMap::VERSION
  s.authors     = ["HornsAndHooves", "Artem Kuzko", "Zachary Belzer", "Sergey Potapov", "Bruce Burdick"]
  s.email       = ["a.kuzko@gmail.com", "zbelzer@gmail.com", "blake131313@gmail.com", "rubygems.org@bruceburdick.com"]
  s.homepage    = "https://github.com/HornsAndHooves/flat_map"
  s.licenses    = ["LICENSE"]
  s.summary     = %q{Deep object graph to a plain properties mapper}
  s.description = %q{This library allows to map accessors and properties of deeply
    nested object graph to a plain mapper object with flexible behavior}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_dependency "activesupport", ">= 5"
  s.add_dependency "activerecord", ">= 5"
  s.add_dependency "yard"

  s.add_development_dependency "rspec", '~> 3.5'
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rake"
end
