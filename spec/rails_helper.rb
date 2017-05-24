# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path("../../spec/dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.fixture_path = "#{::Rails.root}/spec/factories"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
  config.infer_base_class_for_anonymous_controllers = false
  #
  # config.before(:suite) do
  #   DatabaseCleaner.strategy = :truncation
  # end
  #
  # config.before(:each) do
  #   DatabaseCleaner.start
  # end
  #
  # config.after(:each) do
  #   DatabaseCleaner.clean
  # end


end



##################
# Database schema
##################

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :users, :force => true do |t|
      t.string :login
    end
    create_table :posts, :force => true do |t|
      t.string :title
      t.integer :user_id
    end
  end
end


class UsersController < AbstractResourcesController
  def current_user
    # User.create! id: 1010101, login: 'test'
  end
  def authenticate_user!
    true
  end
  def print
    authorize resource
    render text: 'done', layout: false
  end
  def edit
    authorize resource
    render text: 'done', layout: false
  end
  def show
    authorize resource
    render text: 'done', layout: false
  end
  def index
    authorize resource
    render text: 'done', layout: false
  end
  def resource_params
    params.require(:user).permit(:id, :login, posts_attributes: [:id, :title, :_destroy])
  end
end

class PostsController < AbstractResourcesController
  def current_user
    # User.create! id: 1010101, login: 'test'
  end
  def print
    authorize resource
    render text: 'done', layout: false
  end
  def edit
    authorize resource
    render text: 'done', layout: false
  end
  def show
    authorize resource
    render text: 'done', layout: false
  end
  def authenticate_user!
    true
  end
  def index
    authorize resource
    render text: 'done', layout: false
  end
  def resource_params
    params.require(:post).permit(:id, :title, :user_id)
  end
end

class User < AbstractResource
  has_many :posts
  def current_user
  end
end

class Post < AbstractResource
  belongs_to :user
end

class UserPolicy < AbstractResourcePolicy
  def print?
    true
  end
end

class PostPolicy < AbstractResourcePolicy
  def print?
    true
  end
end

Rails.application.routes.draw do
  resources :posts
  resources :users do
    member do
      get :print
    end
    collection do
      get :print
    end
    resources :posts do
      member do
        get :print
      end
      collection do
        get :print
      end
    end
  end

  scope '/admin' do
    resources :users do
      member do
        get :print
      end
      collection do
        get :print
      end
      resources :posts do
        member do
          get :print
        end
        collection do
          get :print
        end
      end
    end
  end

end
