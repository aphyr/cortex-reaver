describe 'User authentication' do
  should 'allow login' do
    page = login
    page.at('#flash_notice').text.strip.should == 'Welcome, Shodan.'
  end

  should 'allow logout' do
    page = get '/users/logout'
    page.at('#flash_notice').text.strip.should.equal 'Goodbye, Shodan.'
  end
end
