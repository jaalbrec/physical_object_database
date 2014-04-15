class Bin < ActiveRecord::Base
	
	belongs_to :batch
	belongs_to :picklist_specification
	has_many :physical_objects
	has_many :boxes
	has_many :workflow_statuses
	include WorkflowStatusModule
	has_many :condition_statuses
	accepts_nested_attributes_for :condition_statuses, allow_destroy: true
	include ConditionStatusModule


end
