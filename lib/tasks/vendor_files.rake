require 'pathname'

# Match
# ([get an invite here](contributing/GETTING_HELP.md))
# [get an invite here](contributing/GETTING_HELP.md)
# Dont Match
# [Heroku support](https://www.heroku.com/support)
# [Heroku support](http://www.heroku.com/support)
RELATIVE_LINK_REGEX = %r{
  \[(?<title>.*)\]            # Match title
  \((?<link>[^(http)].*?)\)   # Match all non-http links
}x

def new_link(file, link)
  if link.end_with?('CODE_OF_CONDUCT.md')
    'conduct' # Special case we manually write
  elsif link.start_with?('mailto:') || link.start_with?('http')
    link
  else
    directory = Pathname.new(File.dirname(file))               # The directory : doc/contributing
    link_path = Pathname.new(link)                             # The path of the link : ../TROUBLESHOOTING.md
    new_link = File.expand_path(link_path, directory)          # The full local path : /path/to/site/doc/TROUBLESHOOTING.md
    new_link = new_link.gsub(Dir.pwd, '')                      # Remove the local part : /doc/TROUBLESHOOTING.md
    new_link.gsub!(/.md$/, '.html')                            # Remove .md
    new_link
  end
end

def write_file(file, to)
  content = File.read(file)
  content.gsub!(RELATIVE_LINK_REGEX) do |match_data|
    new_link = new_link(file.downcase, Regexp.last_match[:link].downcase)
    "[#{Regexp.last_match[:title]}](#{new_link})"
  end

  FileUtils.mkpath(File.dirname(to))
  File.write(to, content)
end

directory "vendor"
directory "vendor/bundler" => ["vendor"] do
  system "git clone https://github.com/bundler/bundler.git vendor/bundler"
end

task :update_vendor => ["vendor/bundler"] do
  Dir.chdir("vendor/bundler") { sh "git fetch" }
end

desc "Pulls in pages maintained in the bundler repo."
task :repo_pages => [:update_vendor] do
  Dir.chdir "vendor/bundler" do
    sh "git reset --hard HEAD"
    sh "git checkout origin/master"

    Dir['doc/**/*.md'].each do |file|
      file_name = file[0..-4] # Removes .md suffix
      to = File.expand_path("../../source/#{file_name}.html.md").downcase
      write_file(file, to)
    end

    write_file("CODE_OF_CONDUCT.md", File.expand_path("../../source/conduct.html.md"))
  end
end

directory "vendor/bundler.github.io" => ["vendor"] do
  system "git clone https://github.com/bundler/bundler.github.io vendor/bundler.github.io"
end

task :update_site => ["vendor/bundler.github.io"] do
  Dir.chdir "vendor/bundler.github.io" do
    sh "git checkout master"
    sh "git reset --hard HEAD"
    sh "git pull origin master"
  end
end