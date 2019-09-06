# frozen_string_literal: true

require 'active_recall/base'
require 'active_recall/deck_methods'
require 'active_recall/item_methods'
require 'active_recall/models/deck'
require 'active_recall/models/item'
require 'active_recall/version'

ActiveRecord::Base.send(:include, ActiveRecall::Base)
