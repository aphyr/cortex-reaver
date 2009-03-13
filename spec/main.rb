#!/usr/bin/env ruby

require 'ramaze/spec/helper'

begin
  # Create a new CR setup
  bin = "#{File.dirname(__FILE__)}/../bin/cortex_reaver"
  root = "/tmp/cortex-reaver-test-#{Process.pid}"
  Dir.chdir root
  `bin --migrate`
  `bin --start`
  
  describe MainController do
    behaves_like 'http', 'xpath'
    it 'should show main page' do
      got = get('/')
      got.status.should == 200
      puts got.body
      got.at('//title').text.strip.should == 'Aphyr'
    end
  end
  
ensure
  begin
    `bin --stop`
  rescue => e
    puts "Unable to stop Cortex Reaver: #{e}"
  end
  FileUtils.rm_rf root
end
