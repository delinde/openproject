#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
ActiveRecord::Base.establish_connection(
  :adapter => defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jdbcsqlite3' : 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'test.db')
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :first_name
      t.string :last_name
      t.timestamps
    end

    create_table :journals, :force => true do |t|
      t.belongs_to :journaled, :polymorphic => true
      t.belongs_to :user, :polymorphic => true
      t.string :user_name
      t.text :changed_data
      t.integer :number
      t.string :tag
      t.timestamps
    end
  end
end

CreateSchema.suppress_messages do
  CreateSchema.migrate(:up)
end

class User < ActiveRecord::Base
  journaled

  def name
    [first_name, last_name].compact.join(' ')
  end

  def name=(names)
    self[:first_name], self[:last_name] = names.split(' ', 2)
  end
end

class MyCustomVersion < VestalVersions::Version
end
