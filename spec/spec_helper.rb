# frozen_string_literal: true

require "active_record"
require "active_support"
require "sidenotes"
require "fileutils"
require "tmpdir"

# Set up in-memory SQLite database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Suppress schema migration output
ActiveRecord::Schema.verbose = false

# Define test schema
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false, limit: 255
    t.integer :age
    t.string :role, default: "member"
    t.string :type # STI column
    t.timestamps
  end

  add_index :users, :email, unique: true
  add_index :users, :name

  create_table :posts, force: true do |t|
    t.string :title, null: false
    t.text :body
    t.integer :user_id, null: false
    t.string :status, default: "draft"
    t.timestamps
  end

  add_index :posts, :user_id
  add_index :posts, %i[user_id status]

  create_table :comments, force: true do |t|
    t.text :body, null: false
    t.references :commentable, polymorphic: true, null: false
    t.integer :user_id, null: false
    t.timestamps
  end

  create_table :tags, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :posts_tags, id: false, force: true do |t|
    t.integer :post_id, null: false
    t.integer :tag_id, null: false
  end

  add_index :posts_tags, %i[post_id tag_id], unique: true

  create_table :profiles, force: true do |t|
    t.integer :user_id, null: false
    t.string :bio
    t.string :avatar_url
    t.timestamps
  end

  create_table :categories, force: true do |t|
    t.string :name, null: false
    t.integer :parent_id
    t.timestamps
  end
end

# Define test models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy

  enum :role, { member: "member", admin: "admin", moderator: "moderator" }
end

# STI models
class AdminUser < User
end

class ModeratorUser < User
end

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_and_belongs_to_many :tags

  enum :status, { draft: "draft", published: "published", archived: "archived" }
end

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
end

class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
end

class Profile < ApplicationRecord
  belongs_to :user
end

class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: "parent_id", dependent: :destroy
end

# Model without a table
class OrphanModel < ApplicationRecord
  self.abstract_class = true
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random

  config.before(:each) do
    Sidenotes.reset_configuration!
  end

  config.around(:each) do |example|
    Dir.mktmpdir("sidenotes-test") do |dir|
      @test_dir = dir
      Dir.chdir(dir) do
        example.run
      end
    end
  end
end
