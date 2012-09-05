#
# Application Template
#

repo_url = "https://raw.github.com/tachiba/rails3_template/master"
gems = {}

#
# Gemfile
#
gem 'mysql2', git: 'git://github.com/tachiba/mysql2.git'

# colorful logging(ANSI color)
gem 'rainbow'

# pagination
gem 'kaminari'

# form
gem 'dynamic_form'

# process monitor
gem 'god', require: false

# capistrano
gem_group :deployment do
  gem 'rvm-capistrano'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_colors'
end

# test
gem_group :test do
  gem "rspec-rails"
  gem "factory_girl_rails", "~> 3.0"
  gem 'faker'
  gem 'sqlite3'
end

comment_lines 'Gemfile', "gem 'sqlite3'"
uncomment_lines 'Gemfile', "gem 'therubyracer'"
uncomment_lines 'Gemfile', "gem 'unicorn'"

# whenever
if yes?("Would you like to install whenever?")
  gem 'whenever', require: false
end

# redis
gems[:redis] = yes?("Would you like to install redis?")
if gems[:redis]
  gem 'redis'

  # resque
  gems[:resque] = yes?("Would you like to install resque?")
  if gems[:resque]
    gem 'resque'
  end

  # redis-rails
  gems[:redis_rails] = yes?("Would you like to install redis-rails?")
  if gems[:redis_rails]
    gem 'redis-rails'
  end
end

# twitter bootstrap
gems[:bootstrap] = yes?("Would you like to install bootstrap?")
if gems[:bootstrap]
  gem 'less-rails'
  gem 'twitter-bootstrap-rails', group: 'assets'
end

# feedzirra
if yes?("Would you like to install feedzirra?")
  gem 'feedzirra'
end

# nokogiri
if yes?("Would you like to install nokogiri?")
  gem 'nokogiri'
end

# xml-sitemap
if yes?("Would you like to install xml-sitemap?")
  gem 'xml-sitemap'
end

#
# Bundle install
#
run "bundle install"

# capify application
capify!

#
# Files and Directories
#

remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"

# lib
empty_directory "lib/runner"
empty_directory "lib/jobs"

# config
create_file "config/config.yml", "empty: true"
create_file "config/schedule.rb"
remove_file "config/deploy.rb"

get "#{repo_url}/config/redis.yml", 'config/redis.yml'

get "#{repo_url}/config/deploy.rb", 'config/deploy.rb'
gsub_file "config/deploy.rb", /%app_name%/, app_name
gsub_file "config/deploy.rb", /%app_name_classify%/, app_name.classify

get "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'
gsub_file "config/unicorn.rb", /%app_name%/, app_name

# initializers
if gems[:redis_rails]
  gsub_file "config/initializers/session_store.rb", /:cookie_store, .+/, ":redis_store, servers: $redis_store, expires_in: 30.minutes"
end

get "#{repo_url}/config/initializers/config.rb", 'config/initializers/config.rb'
get "#{repo_url}/config/initializers/rainbow.rb", 'config/initializers/rainbow.rb'

if gems[:redis]
  get "#{repo_url}/config/initializers/redis.rb", 'config/initializers/redis.rb'

  if gems[:resque]
    get "#{repo_url}/config/initializers/resque.rb", 'config/initializers/resque.rb'
  end
end

# god
empty_directory "config/god"
get "#{repo_url}/config/god/unicorn.rb", 'config/god/unicorn.rb'
gsub_file "config/god/unicorn.rb", /%app_name%/, app_name

#
# Generators
#
if gems[:bootstrap]
  generate 'bootstrap:install'

  if yes?("Would you like to create FIXED layout?(yes=FIXED, no-FLUID)")
    generate 'bootstrap:layout application fixed'
  else
    generate 'bootstrap:layout application fluid'
  end
end

#
# Git
#
git :init
git :add => '.'
git :commit => '-am "Initial commit"'
