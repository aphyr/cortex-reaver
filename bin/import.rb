#!/usr/bin/ruby

puts `#{File.dirname(__FILE__)}/cortex_reaver -rf #{ARGV.first}`

require File.dirname(__FILE__) + '/../lib/cortex_reaver'

CortexReaver.setup ARGV.first

c = Sequel.connect('mysql://cortex_reaver:RyReajOuc7@localhost/cortex_reaver')
f = Sequel.connect('mysql://cortex_reaver:RyReajOuc7@localhost/fiachran')

# Journals
puts "Journals..."
f[:journals].each do |journal|
  journal[:user_id] = journal.delete :author_id
  journal[:name] = Journal.canonicalize journal[:title]
  c[:journals] << journal
end

# Projects
puts "Projects..."
f[:projects].each do |project|
  project[:user_id] = project.delete :author_id
  project[:name] = Project.canonicalize project[:title]
  c[:projects] << project
end

# Photos
puts "Photographs..."
f[:photographs].each do |photograph|
  photograph[:user_id] = photograph.delete :author_id
  photograph[:name] = Photograph.canonicalize photograph[:title]
  c[:photographs] << photograph
end

# Comments
puts "Comments..."
f[:comments].each do |comment|
  if comment[:email] == 'aphyr@aphyr.com'
    comment[:user_id] = 1
  end
  comment[:name] = comment.delete :author
  c[:comments] << comment
end

# Tags
puts "Tags..."
f[:tags].each do |tag|
  tag[:title] = tag[:name]
  tag[:name] = Tag.canonicalize tag[:name]
  c[:tags] << tag
end

[:journals_tags, :projects_tags, :photographs_tags].each do |t|
  f[t].each do |r|
    c[t] << r
  end
end


puts "Fixing blank comment titles"
Comment.infer_blank_titles

puts "Fixing tag counts"
Tag.filter({:name => ''} | {:title => ''}).all.each do |tag|
  tag.delete
end
Tag.refresh_counts

puts "Refreshing comment counts..."
Journal.refresh_comment_counts
Photograph.refresh_comment_counts
Project.refresh_comment_counts

puts "Refreshing cached render fields..."
Journal.refresh_render_caches
Project.refresh_render_caches
Comment.refresh_render_caches
