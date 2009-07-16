describe 'Main Controller' do
  it 'should show main page' do
    doc = get '/'
    doc.at('//title').text.strip.should.equal 'Cortex Reaver'
  end
end
