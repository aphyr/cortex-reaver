describe 'Journals' do
  before do
    login
  end

  should 'create a new journal' do
    page = get('/journals/new')
    form = page.forms.find do |f|
      f.action == '/journals/new'
    end
    form.title = 'Frisbee'
    form['name'] = 'frisbee'
    form.tags = 'ultimate, sports'
    form.body = "Amazing game!"
    page = form.submit
    page.at('#flash_notice').text.strip.should.equal "Created journal Frisbee."
  end
end
