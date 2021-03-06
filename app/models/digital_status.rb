class DigitalStatus < ActiveRecord::Base
	require 'json/ext'

	serialize :options, Hash
	belongs_to :physical_object

	DIGITAL_STATUS_START = "transferred"

	AUDIO_OBJECT_AUTO_ACCEPT = 40

	serialized_empty_hash = "--- {}\n"

	
	# This scope returns an array of arrays containing all of the current digital statuses
	# and their respective counts: [['failed', 3], ['queued', 10], etc]
	scope :unique_statuses, -> {
		DigitalStatus.connection.execute(
			"SELECT y.state, count(*) as count 
			FROM (
				SELECT ds.id, ds.physical_object_id, ds.state AS state, ds.updated_at
				FROM (
					SELECT MAX(id) as id
					FROM digital_statuses
					GROUP BY physical_object_id
				) as x INNER JOIN digital_statuses as ds where ds.id = x.id
			) AS y
			GROUP BY state
			ORDER BY state"
		)
	}

	# this scope takes a status name ('transferred', 'accepted', failed', etc) and returns all
	# physical objects currently in that state
	scope :current_status, lambda {|i| 
    PhysicalObject.find_by_sql(
    	"SELECT physical_objects.*
			FROM (
				SELECT ds.physical_object_id as id
				FROM (
					SELECT MAX(id) as id
					FROM digital_statuses
					GROUP BY physical_object_id
				) as x INNER JOIN digital_statuses as ds 
				WHERE ds.id = x.id and state='#{i}' and options is not null and decided is null
			) as po_ids INNER JOIN physical_objects
			WHERE physical_objects.id = po_ids.id"
    )
  }

  # This scope takes a status name ('transferred', 'accepted', failed', etc) and returns all
  # physical objects currently in that state AND which have an undecided action to process
  scope :current_actionable_status, lambda {|i| 
    PhysicalObject.eager_load(:units).find_by_sql(
    	"SELECT physical_objects.*
			FROM (
				SELECT ds.physical_object_id as id
				FROM (
					SELECT MAX(id) as id
					FROM digital_statuses
					GROUP BY physical_object_id
				) as x INNER JOIN digital_statuses as ds 
				WHERE ds.id = x.id and state='#{i}' and (options is not null and options != '#{serialized_empty_hash}') and decided is null
			) as po_ids INNER JOIN physical_objects
			WHERE physical_objects.id = po_ids.id"
    )
  }

 	# returns a result set containing pairings of state name and the count of physical objects currently in that state
  scope :action_statuses, -> {
  	# this MUST be double quoted - otherwise the \n will be presevered as those characters and not treated as a
  	# carriage return... why does ruby do this?!?!?
  	DigitalStatus.connection.execute(
  		"SELECT state, count(*)
			FROM (
				SELECT id as y_id 
				FROM (
					SELECT MAX(id) as max_id
					FROM digital_statuses
					GROUP BY physical_object_id
				) AS x INNER JOIN digital_statuses AS ds
				WHERE ds.id = x.max_id and (ds.options is not null and ds.options != '#{serialized_empty_hash}') and ds.decided is null 
			) as y INNER JOIN digital_statuses as ds2 
			WHERE ds2.id = y.y_id
			GROUP BY state"
		)
  }

  # all physical objects whose current state is a decision node (one where user must make a choice) AND the choice
  # has been made.
  scope :decided_action_barcodes, -> {
  	# this MUST be double quoted - otherwise the \n will be presevered as those characters and not treated as a
  	# carriage return... why does ruby do this?!?!?
  	DigitalStatus.connection.execute(
  		"SELECT mdpi_barcode, decided
			FROM (
				SELECT physical_object_id, decided
				FROM (
					SELECT max(id) as ds_id
					FROM digital_statuses
					GROUP BY physical_object_id
				) AS ns INNER JOIN digital_statuses as dses
				WHERE dses.id = ns.ds_id and (options is not null and options != '#{serialized_empty_hash}') and decided is not null
			) as ds INNER JOIN physical_objects
			WHERE ds.physical_object_id = physical_objects.id"
		)
  }

  # the number of hours after digitization start that a video physical object is auto-accepted
	@@Video_File_Auto_Accept = 30 * 24
	# the number of hours after digitization start that an audio physical object is auto-accepted
	@@Aufio_File_Auto_Accept = 40 * 24

	scope :expired_audio_physical_objects, -> {
		PhysicalObject.find_by_sql(
			"select physical_objects.*
			from (
				SELECT physical_object_id
				FROM (
					SELECT max(id) as ds_id
					FROM digital_statuses
					GROUP BY physical_object_id
				) AS ns INNER JOIN digital_statuses as dses
				WHERE dses.id = ns.ds_id and (options is not null and options != '--- {}\n') and decided is null
			) as states inner join physical_objects
			where physical_objects.id = states.physical_object_id and date_add(digital_start, INTERVAL #{@@Aufio_File_Auto_Accept} hour) <= utc_timestamp() and audio = true
			order by digital_start"
		)
	}

	scope :expired_video_physical_objects, -> {
		PhysicalObject.find_by_sql(
			"select physical_objects.*
			from (
				SELECT physical_object_id
				FROM (
					SELECT max(id) as ds_id
					FROM digital_statuses
					GROUP BY physical_object_id
				) AS ns INNER JOIN digital_statuses as dses
				WHERE dses.id = ns.ds_id and (options is not null and options != '--- {}\n') and decided is null
			) as states inner join physical_objects
			where physical_objects.id = states.physical_object_id and date_add(digital_start, INTERVAL #{@@Video_File_Auto_Accept} hour) <= utc_timestamp() and video = true
			order by digital_start"
		)
	}

	def self.test(*barcode)
		barcode ||= ["40000000031296"]
		"{
			\"barcode\": #{barcode.first},
			\"state\":\"failed\",
			\"attention\":\"true\",
			\"message\":\"msg\",
			\"options\":{
     		\"to_delete\": \"Discard this object and redigitize or re-upload it\" 
				}
		}"
	end

	def self.unique_statuses_query
			"SELECT y.state, count(*) as count 
			FROM (
				SELECT ds.id, ds.physical_object_id, ds.state AS state, ds.updated_at
				FROM (
					SELECT MAX(id) as id
					FROM digital_statuses
					GROUP BY physical_object_id
				) as x INNER JOIN digital_statuses as ds where ds.id = x.id
			) AS y
			GROUP BY state
			ORDER BY state"
	end

	def from_json(json)
		obj = JSON.parse(json, symbolize_names: true)
		self.physical_object_mdpi_barcode = obj[:barcode]
		po = PhysicalObject.where(mdpi_barcode: self.physical_object_mdpi_barcode).first
		unless po.nil?
			self.physical_object_id = po.id
		end
		self.state = obj[:state]
		self.message = obj[:message]
		self.accepted = false
		self.attention = obj[:attention]
		self.decided = nil
		self.options = obj[:options]
		self
	end

	# this no longer appears to be in use... the overrided versions with signature from_xml(mdpi_barcode, xml)
	# appears to have replaced this one.
  def from_xml(xml)
    self.physical_object_mdpi_barcode = xml.xpath("/pod/data/id").text
    po = PhysicalObject.where(mdpi_barcode: self.physical_object_mdpi_barcode).first
    unless po.nil?
      self.physical_object_id = po.id
    end
    #FIXME
    #self.state = obj[:state]
    self.message = xml.xpath("/pod/data/message").text
    #FIXME
    #self.accepted = false
    self.attention = xml.xpath("/pod/data/attention").text
    #self.decided
    #self.decided = nil
    options_hash = {}
    xml.xpath("/pod/data/options/option").each do |option|
      options_hash[option.xpath("state").text.to_sym] = option.xpath("description").text
    end
    self.options = options_hash
    self
  end

	def select_options
		self.options.map{|key, value| [value, key.to_s]}
	end
  
  # FIXME: consider dropping physical_object_mdpi_barcode as attribute
  def from_xml(mdpi_barcode, xml)
    self.physical_object_mdpi_barcode = mdpi_barcode
    po = PhysicalObject.where(mdpi_barcode: self.physical_object_mdpi_barcode).first
    unless po.nil?
      self.physical_object_id = po.id
    end
    self.state = xml.xpath("/pod/data/state").text
    self.message = xml.xpath("/pod/data/message").text
    self.accepted = false
    self.attention = xml.xpath("/pod/data/attention").text
    self.decided = nil
    options_hash = {}
    xml.xpath("/pod/data/options/option").each do |option|
      options_hash[option.xpath("state").text.to_sym] = option.xpath("description").text
    end
    self.options = options_hash
    self
  end

	def requires_attention?
		attention and !decided.blank?
	end

	def decided?
		!decided.blank?
	end

	# need to nil out the options hash if there are no options.
	def before_save(record)
		if options.size == 0
			options = nil
		end
	end
end
