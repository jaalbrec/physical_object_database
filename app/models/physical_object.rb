class PhysicalObject < ActiveRecord::Base

  belongs_to :box
  belongs_to :bin
  belongs_to :picklist
  belongs_to :container
  has_one :technical_metadatum
  has_many :workflow_statuses
  has_many :digital_files
  

  attr_accessor :formats 
  def formats
    {
      # "Cassette Tape" => "Cassette Tape", 
      # "Compact Disc" => "Compact Disc", 
      # "LP" => "LP", 
      "Open Reel Tape" => "Open Reel Tape"
    }
  end

  accepts_nested_attributes_for :technical_metadatum

  scope :search_by_catalog, lambda {|query| where(["shelf_number = ? OR call_number = ?", query, query])}
  
  scope :search_by_barcode, lambda {|barcode| where(["mdpi_barcode = ? OR iucat_barcode = ?", barcode, barcode])}
  
  scope :search_id, lambda {|i| 
    where(['mdpin_barcode like ? OR iucat_barcode like ? OR shelf_number like ? OR call_number like ?', i, i, i, i])
  }
  
  def splitable?(s="")
    s.include? "-" or s.include? ","
  end

  def container_id
    if !box.nil?
      box.id
    elsif !bin.nil?
      bin.id
    else
      nil
    end
  end

  def create_tm(f)
    if f == "Cassette Tape"
      CassetteTapeTm.new
    elsif f == "Compact Disc"
      CompactDiscTm.new
    elsif f == "LP"
      LpTm.new
    elsif f == "Open Reel Tape"
      OpenReelTm.new
    else
      raise 'Unknown format type' + format
    end 
  end

  def format_class
    if format == "OpenReelTm"
      OpenReelTm.class
    end
  end
end
