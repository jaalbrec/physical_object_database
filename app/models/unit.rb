class Unit < ActiveRecord::Base
  validates :abbreviation, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true

  has_many :physical_objects

  def home
    institution + 
    (campus.blank? ? "" : (institution.blank? ? "" : ", ") + campus)
  end

  def spreadsheet_descriptor
    abbreviation
  end
end
