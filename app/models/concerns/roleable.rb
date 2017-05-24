require 'active_support/concern'

# TODO 05-05-2015 make Roleable work with other resource_class too

module Roleable
  extend ActiveSupport::Concern

  included do
    # has_many :somthing
    enum role: [:no_access, :guest, :external_business_partner, :user, :super_user, :account_admin, :admin]
    attr_accessor :max_role
    after_initialize :set_default_role, :if => :new_record?

    validates_with RoleValidator

  end

  module ClassMethods
    def policed_roles user
      User.roles.keys.map {|role| [role.titleize,role] if User.roles[role] <= User.roles[user.role]   }.compact
    end
  end

  # role management
  # ---------------
  # enum listing possible roles
  # max_role setting the model max role to that of the current user - you never can promote anyone above your own level
  # set_default_role sets the role of a new user
  #

  class RoleValidator < ActiveModel::Validator
    attr_accessor :user
    def validate(record)
      @user = record
      Rails.logger.info ("roles: old %s new %s" % [ User.roles[record.previous_version.role], User.roles[record.role] ] ) rescue "no previous role"
      if max_role_exhausted and old_role_less_than_new
        record.errors[:role] << I18n.t('.assigned_role_not_allowed')
      end
    end

    def old_role_less_than_new
      User.roles[user.previous_version.role] < User.roles[user.role]
    rescue
      false
    end

    def max_role_exhausted
      User.roles[user.role] > User.roles[user.max_role]
    rescue
      false
    end
  end



  def set_default_role
   self.role ||= :user
  end


end
