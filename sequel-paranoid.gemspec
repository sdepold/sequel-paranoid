Gem::Specification.new do |s|
  s.name        = 'sequel-paranoid'
  s.version     = '0.2.0'
  s.date        = '2013-07-30'
  s.summary     = "A plugin for the Ruby ORM Sequel, that allows soft deletion of database entries."
  s.description = "Use this plugin to mark a model instance as deleted without loosing its actual data."
  s.authors     = ["Sascha Depold"]
  s.email       = 'sascha@depold.com'
  s.files       = ["lib/sequel/plugins/paranoid.rb"]
  s.homepage    = 'https://github.com/sdepold/sequel-paranoid'
  s.license     = "MIT"

  s.add_runtime_dependency "sequel"
end
