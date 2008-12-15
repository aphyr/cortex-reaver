$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
 
require 'rubygems'
require 'cortex_reaver/version'
require 'rake/gempackagetask'
require 'find'
 
# Gemspec
Gem::Specification.new do |s|
  s.rubyforge_project = 'cortex-reaver'
 
  s.name = 'cortex-reaver'
  s.version = CortexReaver::APP_VERSION
  s.author = CortexReaver::APP_AUTHOR
  s.email = CortexReaver::APP_EMAIL
  s.homepage = CortexReaver::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary = 'A dangerous Ruby blog engine, with a photographic memory.'
 
  s.files = FileList['{bin,lib}/**/*', 'LICENSE', 'README'].to_a
  s.executables = ['cortex_reaver', 'console']
  s.require_path = 'lib'
  s.has_rdoc = true
 
  s.required_ruby_version = '>= 1.8.5'
 
  s.add_dependency('ramaze', '= 2008.11')
  s.add_dependency('builder', '~> 2.1.2')
  s.add_dependency('erubis', '~> 2.6.2')
  s.add_dependency('hpricot', '~> 0.6')
  s.add_dependency('BlueCloth', '~> 1.0.0')
  s.add_dependency('sequel', '~> 2.7.1')
  s.add_dependency('mongrel', '~> 1.1.5')
  s.add_dependency('exifr', '~> 0.10.7')
# This doesn't work right on Debian yet
# s.add_dependency('RMagick', '~> 2.5.1')
end
