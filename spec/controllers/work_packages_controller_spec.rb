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

require File.expand_path('../../spec_helper', __FILE__)

describe WorkPackagesController do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
      end
    end
  end

  def self.become_member_with_permissions(permissions)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role = FactoryGirl.create(:role, :permissions => permissions)

      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_view_planning_element_permissions
    become_member_with_permissions [:view_planning_elements, :view_work_packages]
  end

  before do
    User.stub(:current).and_return current_user
  end

  #=======================================================================

  let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:current_user) { FactoryGirl.create(:user) }

  describe 'show.html' do

    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'show', :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        before do
          get 'show', :id => planning_element.id
        end

        it 'renders the show builder template' do
          response.should render_template('work_packages/show', :formats => ["html"], :layout => :base)
        end
      end
    end
  end

  describe 'new.html' do
    describe 'w/o specifying a project_id' do
      before do
        get 'new'
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 404
      end
    end

    describe 'w/o being a member' do
      before do
        get 'new', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions' do
      become_member_with_permissions [:add_work_packages]

      before do
        get 'new', :project_id => project.id
      end

      it 'renders the new builder template' do
        response.should render_template('work_packages/new', :formats => ["html"], :lacout => :base)
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end

    describe 'w/ beeing a member
              w/o having the necessary permissions' do
      become_member_with_permissions []

      before do
        get 'new', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end
  end

  describe :work_package do
    describe 'when beeing allowed to see the work_package' do
      become_member_with_view_planning_element_permissions

      it 'should return the work_package' do
        controller.params = { id: planning_element.id }

        controller.work_package.should == planning_element
      end

      it 'should return nil for non existing work_packages' do
        controller.params = { id: 0 }

        controller.work_package.should be_nil
      end
    end

    describe 'when not beeing allowed to see the work_package' do
      it 'should return nil' do
        controller.params = { id: planning_element.id }

        controller.work_package.should be_nil
      end
    end
  end

  describe :new_work_package do
    describe 'when the type is "PlanningElement"' do
      before do
        controller.params = { :project_id => project.id, :type => 'PlanningElement' }
      end

      it 'should return a work package' do
        controller.new_work_package.should be_a(PlanningElement)
      end

      it 'the object should be a new record' do
        controller.new_work_package.should be_new_record
      end

      it 'should have the project associated' do
        controller.new_work_package.project.should == project
      end
    end

    describe 'when the type is "Issue"' do
      before do
        controller.params = { :project_id => project.id, :type => 'Issue' }
      end

      it 'should return a work package' do
        controller.new_work_package.should be_a(Issue)
      end

      it 'the object should be a new record' do
        controller.new_work_package.should be_new_record
      end

      it 'should have the project associated' do
        controller.new_work_package.project.should == project
      end
    end

    describe 'when the type is "Project"' do
      it "should raise not allowed" do
        controller.params= { :type => 'Project' }

        expect { controller.new_work_package }.to raise_error ArgumentError
      end
    end
  end

  describe :project do
    it "should be the work_packages's project" do
      controller.stub!(:work_package).and_return(planning_element)

      controller.project.should == project
    end
  end

  describe :journals do
    it "should return all the work_package's journals except the first one" do
      journal = FactoryGirl.create(:planning_element_journal, journaled: planning_element,
                                                              changed_data: { description: [planning_element.description, "blubs"]},
                                                              version: 2
                                  )
      planning_element.reload

      controller.stub!(:work_package).and_return(planning_element)

      controller.journals.should == [journal]
    end

    it "should be empty if the work_package has only one journal" do
      controller.stub!(:work_package).and_return(planning_element)

      controller.journals.should be_empty
    end
  end

  describe :changesets do
    it "should be empty" do
      controller.changesets.should be_empty
    end
  end

  describe :relations do
    it "should be empty" do
      controller.relations.should be_empty
    end
  end

  describe :ancestors do
    let(:project) { FactoryGirl.create(:project_with_trackers) }
    let(:ancestor_issue) { FactoryGirl.create(:issue, :project => project) }
    let(:issue) { FactoryGirl.create(:issue, :project => project, :parent_issue_id => ancestor_issue.id) }

    become_member_with_view_planning_element_permissions

    describe "when work_package is an issue" do
      let(:ancestor_issue) { FactoryGirl.create(:issue, :project => project) }
      let(:issue) { FactoryGirl.create(:issue, :project => project, :parent_issue_id => ancestor_issue.id) }

      it "should return the work_packages ancestors" do
        controller.stub!(:work_package).and_return(issue)

        controller.ancestors.should == [ancestor_issue]
      end
    end

    describe "when work_package is a planning element" do
      let(:descendant_planning_element) { FactoryGirl.create(:planning_element, :project => project,
                                                                                :parent => planning_element) }
      it "should return the work_packages ancestors" do
        controller.stub!(:work_package).and_return(descendant_planning_element)

        controller.ancestors.should == [planning_element]
      end
    end
  end

  describe :descendants do
    it "should be empty" do
      controller.descendants.should be_empty
    end
  end
end
