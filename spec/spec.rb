#!/usr/bin/ruby

require 'rubygems'
require 'fileutils'
require 'bacon'
require 'mechanize'
#require File.expand_path(File.join(File.dirname(__FILE__)) + '/../lib/cortex_reaver')

# Included into Object
module TestHelper
  def get(name = '')
    page = A.get('http://localhost:7000/' + name.to_s)
  end

  def login
    page = A.get('/users/login')
    form = page.forms.find do |f|
      f.action == '/users/login'
    end
    form.login = 'shodan'
    form.password = 'citadelstation'
    page = form.submit
  end
end

class Object
  include TestHelper
end

class Test
#  def describe(*args, &block)
#    Bacon::Context.new(args.join(' '), &block).run
#  end

  def setup
    # Create a new CR setup
    @bin = File.expand_path("#{File.dirname(__FILE__)}/../bin/cortex_reaver")
    @root = "/tmp/cortex-reaver-test-#{Process.pid}"
    Dir.mkdir @root
    Dir.chdir @root
    `#{@bin} --migrate --force`
  #  File.open('cortex_reaver.yaml', 'w') do |file|
  #    file.write YAML::dump({:daemon => true})
  #  end
    `#{@bin} --start `
    
    sleep 1

    Object.const_set 'A', WWW::Mechanize.new
  end

  def run
    begin
      setup
      Bacon.summary_on_exit
      run_test :main
      run_test :user
      run_test :journal
    rescue
    ensure
      teardown
    end
  end

  def teardown
    begin
      `#{@bin} --stop`
    rescue => e
      puts "Unable to stop Cortex Reaver: #{e}"
    end
    FileUtils.rm_rf @root
  end

  def run_test(name)
    eval(File.read(File.join(File.dirname(__FILE__), name.to_s + '.rb')))
#    require File.join(File.dirname(__FILE__), name)
  end
end

Test.new.run
