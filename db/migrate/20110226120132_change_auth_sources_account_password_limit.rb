#-- encoding: UTF-8
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

class ChangeAuthSourcesAccountPasswordLimit < ActiveRecord::Migration
  def self.up
    change_column :auth_sources, :account_password, :string, :limit => nil, :default => ''
  end

  def self.down
    change_column :auth_sources, :account_password, :string, :limit => 60, :default => ''
  end
end
