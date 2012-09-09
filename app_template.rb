#
# Application Template
#

repo_url = "https://raw.github.com/tachiba/rails3_template/master"
gems = {}

@app_name = app_name

def get_and_gsub(source_path, local_path)
  get source_path, local_path

  gsub_file local_path, /%app_name%/, @app_name
  gsub_file local_path, /%app_name_classify%/, @app_name.classify
  gsub_file local_path, /%working_user%/, @working_user
  gsub_file local_path, /%dir_development%/, @dir_development
  gsub_file local_path, /%dir_production%/, @dir_production
  gsub_file local_path, /%remote_repo%/, @remote_repo
end

def gsub_database(localpath)
  return unless @mysql

  gsub_file localpath, /%mysql_username_development%/, @mysql[:username_development]
  gsub_file localpath, /%mysql_remote_host_development%/, @mysql[:remote_host_development]

  gsub_file localpath, /%mysql_username_production%/, @mysql[:username_production]
  gsub_file localpath, /%mysql_password_production%/, @mysql[:password_production]
  gsub_file localpath, /%mysql_remote_host_production%/, @mysql[:remote_host_production]
end

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

# rails-sh
# https://github.com/jugyo/rails-sh
gem 'rails-sh', require: false

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

@working_user = ask("working user?")
@dir_production = ask("production dir?")
@dir_development = ask("development dir?")
@remote_repo = ask("repote git repo? e.g.) username@hostname")

@mysql = false
if yes?("set up mysql now?")
  @mysql = {}
  @mysql[:remote_host_development] = ask("mysql:development remote host?")
  @mysql[:username_development] = ask("mysql:development username?")

  @mysql[:remote_host_production] = ask("mysql:production remote host?")
  @mysql[:username_production] = ask("mysql:production username?")
  @mysql[:password_production] = ask("mysql:production password?")
end

#
# Files and Directories
#

remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"

# views
empty_directory "app/views/shared"

# public
empty_directory "public/system/cache"

# lib
empty_directory "lib/runner"
empty_directory "lib/jobs"

# config
create_file "config/config.yml", "empty: true"
create_file "config/schedule.rb"
remove_file "config/deploy.rb"

get "#{repo_url}/config/redis.yml", 'config/redis.yml'

get_and_gsub "#{repo_url}/config/deploy.rb", 'config/deploy.rb'
get_and_gsub "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'

# config/database.yml
remove_file "config/database.yml"
get_and_gsub "#{repo_url}/config/database.yml", 'config/database.yml'
gsub_database 'config/database.yml'

# config/application.rb
insert_into_file "config/application.rb", %(config.autoload_paths += Dir[Rails.root.join('lib')]),
                 after: "# Custom directories with classes and modules you want to be autoloadable.\n"

insert_into_file "config/application.rb", %(config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]),
                 after: "# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.\n"

# config/environments
insert_into_file "config/environments/production.rb",
                 %(config.assets.precompile += %w( *.css *.js )),
                 after: "# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)\n"

insert_into_file "config/environments/production.rb",
                 %(config.action_controller.page_cache_directory = Rails.root.join("public", "system", "cache")),
                 after: "# config.cache_store = :mem_cache_store\n"

insert_into_file "config/environments/production.rb",
                 %(config.assets.static_cache_control = "public, max-age=#{60 * 60 * 24}"),
                 after: "# config.cache_store = :mem_cache_store\n"

# config/god
empty_directory "config/god"
get_and_gsub "#{repo_url}/config/god/unicorn.rb", 'config/god/unicorn.rb'

# config/deploy
empty_directory "config/deploy"
get_and_gsub "#{repo_url}/config/deploy/production.rb", 'config/deploy/production.rb'

# config/initializers
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
remove_file '.gitignore'
get "#{repo_url}/gitignore", '.gitignore'
git :init
git :add => '.'
git :commit => '-am "Initial commit"'
git :remote => "add origin #@remote_repo:#@app_name.git"