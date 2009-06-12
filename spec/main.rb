#!/usr/bin/env ruby

require 'ramaze/spec/helper'

begin
  # Create a new CR setup
  bin = "#{File.dirname(__FILE__)}/../bin/cortex_reaver"
  root = "/tmp/cortex-reaver-test-#{Process.pid}"
  Dir.chdir root
  `#{bin} --migrate`
  `#{bin} --start`
  
  describe 'Main Controller' do
    behaves_like 'http', 'xpath'

    def check_page(name = '')
      page = get("/#{name}")
      page.status.should == 200
      page.body.should.not == nil

      doc = Hpricot(page.body)
      doc.at('title').inner_html.should == 'Blog'
      doc.at('h1').inner_html.should == 'Blog'

      doc.search('div#entries').size.should == 1

      doc
    end

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
