$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'cortex_reaver/version'
require 'find'
 
# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'
 
# Gemspec
cortex_reaver_gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'cortex-reaver'
 
  s.name = 'cortex-reaver'
  s.version = CortexReaver::APP_VERSION
  s.author = CortexReaver::APP_AUTHOR
  s.email = CortexReaver::APP_EMAIL
  s.homepage = CortexReaver::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary = 'A dangerous Ruby blog engine, with a photographic memory.'
 
  s.files = FileList['{bin,lib}/**/*', 'LICENSE', 'README'].to_a
  s.executables = ['cortex_reaver']
  s.require_path = 'lib'
  s.has_rdoc = true
 
  s.required_ruby_version = '>= 1.8.6'
 
  s.add_dependency('ramaze', '= 2009.06')
  s.add_dependency('libxml-ruby', '~> 1.1.3')
  s.add_dependency('erubis', '~> 2.6.2')
  s.add_dependency('sanitize', '~> 1.0.6')
  s.add_dependency('BlueCloth', '~> 1.0.0')
  s.add_dependency('sequel', '~> 3.2.0')
  s.add_dependency('sequel_notnaughty', '~> 0.6.2')
  s.add_dependency('thin', '~> 1.0.0')
  s.add_dependency('exifr', '~> 0.10.7')
  s.add_dependency('construct', '~> 0.1.2')
  s.add_dependency('rmagick', '~> 2.5.1')
  s.add_dependency('cssmin', '~>1.0.2')
  s.add_dependency('jsmin', '~>1.0.1')
end
 
Rake::GemPackageTask.new(cortex_reaver_gemspec) do |p|
  p.need_tar_gz = true
end
 
Rake::RDocTask.new do |rd|
  rd.main = 'Cortex Reaver'
  rd.title = 'Cortex Reaver'
  rd.rdoc_dir = 'doc'
 
  rd.rdoc_files.include('lib/**/*.rb')
end
 
desc "install Cortex Reaver"
task :install => :gem do
  sh "gem install #{File.dirname(__FILE__)}/pkg/cortex-reaver-#{CortexReaver::APP_VERSION}.gem"
end
 
desc "remove end-of-line whitespace"
task 'strip-spaces' do
  Dir['lib/**/*.{css,js,rb,rhtml,sample}'].each do |file|
    next if file =~ /^\./
 
    original = File.readlines(file)
    stripped = original.dup
 
    original.each_with_index do |line, i|
      if line =~ /\s+\n/
        puts "fixing #{file}:#{i + 1}"
        p line
        stripped[i] = line.rstrip
      end
    end
 
    unless stripped == original
      File.open(file, 'w') do |f|
        stripped.each {|line| f.puts(line) }
      end
    end
  end
end
