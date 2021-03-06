class PhysicalObjectsController < ApplicationController
  before_action :set_physical_object, only: [:show, :edit, :edit_ephemera, :update, :update_ephemera, :destroy, :workflow_history, :split_show, :split_update, :unbin, :unbox, :unpick, :ungroup, :generate_filename]  
  before_action :set_new_physical_object, only: [:new, :create_multiple]
  before_action :set_new_physical_object_with_params, only: [:create]
  before_action :set_box_and_bin_by_barcodes, only: [:create, :create_multiple, :update]
  before_action :set_picklists, only: [:edit]
  before_action :normalize_dates, only: [:create, :update]
  helper :all

  def download_spreadsheet_example
    send_file("#{Rails.root}/public/CSV_Import.xlsx", filename: "CSV_Import.xlsx")
  end

  def new
    # we instantiate an new object here because rails will pick up any default values assigned
    # by the database and the form will be prepopulated with those values
    # we can also pass a hash to PhysicalObject.new({iucat_barcode => "123436"}) to assign defaults programmatically
    #default format for now
    format = PhysicalObject.formats["Open Reel Audio Tape"]
    @physical_object.format = format
    @tm = @physical_object.ensure_tm
    @dp = @physical_object.ensure_digiprov
    @formats = PhysicalObject.formats
    @edit_mode = true
    @action = "create"
    @submit_text = "Create Physical Object"
    @display_assigned = true

    if !params[:group_key_id].nil?
      @group_key = GroupKey.find(params[:group_key_id])
      @physical_object.group_key = @group_key
      @physical_object.group_position = @group_key.physical_objects_count + 1
    end
  end

  def create
    # catch whether this was from a "create multiple physical objects" link
    if params[:repeat] == "true"
      @repeat = true
    end
    @tm = @physical_object.ensure_tm
    @dp = @physical_object.ensure_digiprov
    @tm.assign_attributes(tm_params)
    if @physical_object.valid? && @tm.valid? && @dp.valid?
      saved = @physical_object.save 
      saved = @tm.update_attributes(tm_params) if saved
    end
    if saved
      flash[:notice] = "Physical Object was successfully created.".html_safe
    end


    if @repeat != true and saved
      redirect_to(:action => 'index')
    else
      @edit_mode = true
      if @repeat and saved
        @physical_object = PhysicalObject.new(physical_object_params)
        @tm = @physical_object.ensure_tm
        @dp = @physical_object.ensure_digiprov
        @tm.assign_attributes(tm_params)
      else
        # for failed save, carry over tm attributes
        @tm.assign_attributes(tm_params)
      end
      @display_assigned = true
      render('new')
    end
  end

  def index
    @physical_objects = PhysicalObject.eager_load(:group_key, :unit, :bin, :box).all.references(:group_key).packing_sort
    if request.format.html?
      @physical_objects = @physical_objects.paginate(page: params[:page])
    end
  end

  def contained
    contained_status_ids = WorkflowStatusTemplate.where(name: ["Binned", "Boxed"]).map { |wst| wst.id }
    if params[:physical_object]
      @start_date = params[:physical_object][:start_date]
      @end_date = params[:physical_object][:end_date]
    end
    if @start_date && @end_date
      @physical_objects = PhysicalObject.all.eager_load(:unit, :picklist, :box, :bin).joins(:workflow_statuses).where("workflow_statuses.workflow_status_template_id IN (?) AND workflow_statuses.created_at >= ? AND workflow_statuses.created_at <= ?", contained_status_ids, @start_date, @end_date)
    else
      @physical_objects = PhysicalObject.none
    end
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def show
    @action = "show"
    @edit_mode = false;
    @display_assigned = true
    if request.referer.to_s.include? "quality_control"
      redirect_to digital_provenance_path(params[:id])
    else
      render 'show'
    end
  end

  def edit
    @action = 'update'
    @edit_mode = true
    @display_assigned = true
  end

  def update
    PhysicalObject.transaction do
      # initial save processes bin, box assignment
      @original_tm = @physical_object.technical_metadatum
      @physical_object.assign_attributes(physical_object_params)
      tm_assigned = true
      if @physical_object.valid?
        @tm = @physical_object.ensure_tm
        @dp = @physical_object.ensure_digiprov
	begin
          @tm.assign_attributes(tm_params)
	rescue
	  tm_assigned = false
        end
      end
      if @physical_object.valid? && @tm.valid? && @dp.valid? && tm_assigned
        updated = @physical_object.save
        updated = @tm.update_attributes(tm_params) if updated
        @tm.reload
        if @original_tm && @original_tm.id != @tm.technical_metadatum.id
          @original_tm.destroy
        end
      end
      if !tm_assigned
        @physical_object.errors[:base] << "Technical Metadata format did not match, which was probably the result of a failed format change.  Verify physical object format and technical metadata, then resubmit."
      end

      if updated 
        flash[:notice] = "Physical Object successfully updated".html_safe
        redirect_to(action: 'index')
      else
        @edit_mode = true
        @display_assigned = true
        render action: :edit  
      end
    end
  end

  def destroy
    if @physical_object.destroy
      flash[:notice] = "Physical Object was successfully deleted.".html_safe
    else
      flash[:notice] = "Physical Object could not be deleted.".html_safe
    end
    redirect_to physical_objects_path
  end

  def workflow_history
    @workflow_statuses = @physical_object.workflow_statuses
  end
  
  def split_show
    if @physical_object.bin or @physical_object.box
      flash[:notice] = "This physical object must be removed from its container (bin or box) before it can be split."
      @display_assigned = true
      @submit_text = ""
      redirect_to action: :show
    else
      @count = 0;
      @display_assigned = true
      @submit_text = ""
    end
  end
  
  def split_update
    split_count = params[:count].to_i
    split_grouped = params[:grouped]
    if @physical_object.bin or @physical_object.box
      flash[:notice] = "This physical object must be removed from its container (bin or box) before it can be split."
    elsif split_count > 1
      (1...split_count).each do |i|
        po = @physical_object.dup
        po.assign_default_workflow_status
        po.mdpi_barcode = 0
	po.ensure_digiprov
	if split_grouped
          po.group_position = @physical_object.group_position + i
	else
	  po.group_position = 1
	  po.group_key = nil
	end
        tm = @physical_object.technical_metadatum.as_technical_metadatum.dup
        tm.physical_object = po
        tm.save
        #po is automatically saved by association
      end
      flash[:notice] = "<i>#{@physical_object.title}</i> was successfully split into #{split_count} records.".html_safe
    else
      flash[:notice] = "<i>#{@physical_object.title}</i> was NOT split.".html_safe
    end
    if URI(request.referer).path == split_show_physical_object_path(@physical_object)
      if split_grouped
        redirect_to controller: 'group_keys', action: "show", id: @physical_object.group_key
      else
        redirect_to @physical_object
      end
    # for pack_list action, append physical_object[id] param to redirection back, to return to same object in packing process
    elsif URI(request.referer).path.match /pack_list/
      referrer_url = URI.parse(request.referrer) rescue URI.parse(physical_object_path(@physical_object))
      referrer_query = Rack::Utils.parse_nested_query(referrer_url.query)
      # merge was not working, so delete and (re)add the parameter
      referrer_query.delete("physical_object")
      referrer_query["physical_object"] = { "id" => @physical_object.id }
      referrer_url.query = referrer_query.to_query
      redirect_to referrer_url.to_s
    else
      redirect_to :back
    end
  end
  
  def upload_show
    @physical_object = PhysicalObject.new
  end
  
  def upload_update
    if params[:type].nil?
      flash[:notice] = "Please explicitly choose a picklist association (or lack thereof)."
    elsif params[:type].in? ["new", "existing"] and params[:picklist].nil?
      flash[:warning] = "SYSTEM ERROR: Picklist hash not passed."
    elsif params[:type] == "existing" and params[:picklist][:id].to_i.zero?
      flash[:notice] = "Please select an existing picklist."
    elsif params[:type] == "new" and params[:picklist][:name].to_s.blank?
      flash[:notice] = "Please provide a picklist name."
    elsif params[:physical_object].nil?
      flash[:notice] = "Please specify a file to upload."
    else
      @picklist = nil
      if params[:type] == "existing"
        @picklist = Picklist.find_by(id: params[:picklist][:id].to_i)
        flash[:warning] = "SYSTEM ERROR: Selected picklist not found!<br/>Spreadsheet NOT uploaded.".html_safe if @picklist.nil?
      elsif params[:type] == "new"
        @picklist = Picklist.new(name: params[:picklist][:name], description: params[:picklist][:description])
        @picklist.save
        flash[:warning] = "Errors creating picklist:<ul>#{@picklist.errors.full_messages.each.inject('') { |output, error| output += ('<li>' + error + '</li>') }}</ul>Spreadsheet NOT uploaded.".html_safe if @picklist.errors.any?
      end
    end
    if flash[:notice].to_s.blank? and flash[:warning].to_s.blank?
      path = params[:physical_object][:csv_file].path
      filename = params[:physical_object][:csv_file].original_filename
      header_validation = true unless params[:header_validation] == "false"
      upload_results = PhysicalObjectsHelper.parse_csv(path, header_validation, @picklist, filename)
      @spreadsheet = upload_results[:spreadsheet]
      flash[:notice] = "".html_safe
      flash[:notice] = "Created picklist: #{params[:picklist][:name]}.</br>".html_safe if @picklist and params[:type] == "new"
      flash[:notice] += ("Spreadsheet " + ((@spreadsheet.nil? || @spreadsheet.id.nil?) ? "NOT " : "")  + "uploaded.<br/>").html_safe
      flash[:notice] += "CSV headers NOT checked for validation.</br>".html_safe unless header_validation
      flash[:notice] += "#{upload_results['succeeded'].size} record" + (upload_results['succeeded'].size == 1 ? " was" : "s were") + " successfully imported.".html_safe
      if upload_results['failed'].size > 0
        @failed = upload_results['failed']
      end
    else
      redirect_to(action: 'upload_show')
    end
  end

  def create_multiple
    #default format for now
    format = PhysicalObject.formats["CD-R"]
    @physical_object.format = format
    @tm = @physical_object.ensure_tm
    @dp = @physical_object.ensure_digiprov
    @formats = PhysicalObject.formats
    @edit_mode = true
    @action = "create"
    @submit_text = "Create Physical Object"
    @repeat = true
    @display_assigned = true
  end
    
  def unbin
    unless @physical_object.box.nil?
      raise RuntimeError, "A physical object should not be unbin-able if it is in a box..."
    end
    @bin = @physical_object.bin
    @physical_object.bin = nil
    if @bin.nil?
       flash[:notice] = "<strong>Physical Object was not associated to a Bin.</strong>".html_safe
    elsif @physical_object.save
      flash[:notice] = "<em>Physical Object was successfully removed from bin.</em>".html_safe
    else
      flash[:notice] = "<strong>Physical Object was NOT removed from bin.</strong>".html_safe
    end
    unless @bin.nil?
      redirect_to @bin
    else
      redirect_to @physical_object
    end
  end

  def unbox
    @box = @physical_object.box
    @physical_object.box = nil
    if @box.nil?
       flash[:notice] = "<strong>Physical Object was not associated to a Box.</strong>".html_safe
    elsif @physical_object.save
      flash[:notice] = "<em>Physical Object was successfully removed from box.</em>".html_safe
    else
      flash[:notice] = "<strong>Physical Object was NOT removed from box.</strong>".html_safe
    end
    unless @box.nil?
      redirect_to @box
    else
      redirect_to @physical_object
    end
  end

  #called as both AJAX call, from packing screen, and regular call from picklist screen
  def unpick
    # SEE - views/picklists/process_list.html.erb "$("[id^=remove_]").click(function(event) {" javascript
    if @physical_object.group_key.nil?
      @physical_object.picklist = nil
      @physical_object.save
    else
      picklist_id = @physical_object.picklist_id
      @physical_object.group_key.physical_objects.each do |object|
        if object.picklist_id == picklist_id
          object.picklist = nil
          object.save
        end
      end
    end
    new_bc = Integer(params[:mdpi_barcode]) if params[:mdpi_barcode]
    update = (!new_bc.nil? and @physical_object.mdpi_barcode != new_bc)
    if (update)
      @physical_object.mdpi_barcode = new_bc
      update = @physical_object.save
    end
    flash[:notice] = "The Physical Object was removed from the Pick List" + (update ? " and its barcode updated." : ".")
    redirect_to action: "edit"
  end

  def ungroup
    original_group = @physical_object.group_key
    @physical_object.group_position = 1
    @physical_object.group_key = nil
    if @physical_object.save
      # original_group.destroyed? check is not working for some reason
      if GroupKey.where(id: original_group.id).empty?
        flash[:notice] = "The Physical Object was removed from its former Group Key, and that Group Key (containing no objects) has been deleted.  The Physical Object has automatically been assigned to a new Group Key."
        redirect_to @physical_object
      else
        flash[:notice] = "The Physical Object was removed from this Group Key.  (It has automatically been assigned to a new Group Key.)"
        redirect_to :back
      end
    else
      flash[:notice] = "An error occurred.  Physical Object was NOT removed from this Group Key."
      redirect_to :back
    end

  end

  # ajax method to determine if a physical object has emphemera - returns plain text true/false
  def has_ephemera
    has_it = false
    if params[:mdpi_barcode] && !params[:mdpi_barcode].to_i.zero? && (po = PhysicalObject.find_by(mdpi_barcode: params[:mdpi_barcode]))
      if po.current_workflow_status.in? ['Unpacked', 'Returned to Unit']
        has_it = 'returned'
      else
        has_it = po.has_ephemera?
      end
    else
      has_it = "unknown physical Object"
    end
    render plain: "#{has_it}", layout: false
  end

  def edit_ephemera
  end

  # update restricted to 2 epheemra values, with new workflow status log entry
  def update_ephemera
    respond_to do |format|
      @physical_object.assign_attributes(physical_object_params)
      if @physical_object.has_ephemera_was == @physical_object.has_ephemera && @physical_object.ephemera_returned_was == @physical_object.ephemera_returned
        format.html { flash[:warning] = 'foo'; redirect_to @physical_object, flash: { warning: 'No ephemera status changes were submitted.' } }
	format.html { head :no_content }
      elsif @physical_object.save
	@physical_object.duplicate_workflow_status
        format.html { redirect_to @physical_object, notice: 'Ephemera was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: :edit_ephemera }
        format.json { render json: @physical_object.errors, status: :unprocessable_entity }
      end
    end
  end

  def generate_filename
    render plain: @physical_object.generate_filename(sequence: params[:sequence], use: params[:use], extension: params[:extension]), layout: false
  end
  
  private
    def set_physical_object
      @physical_object = PhysicalObject.find(params[:id])
      @tm = @physical_object.technical_metadatum
      @tm = @physical_object.technical_metadatum.as_technical_metadatum unless @tm.nil?
      @dp = @physical_object.ensure_digiprov
      @bin = @physical_object.bin
      @box = @physical_object.box
      @group_key = @physical_object.group_key
    end

    def set_new_physical_object
      @physical_object = PhysicalObject.new
    end

    def set_new_physical_object_with_params
      @physical_object = PhysicalObject.new(physical_object_params)
    end

    def set_picklists
      @picklists = Picklist.all
    end

    def set_box_and_bin_by_barcodes
      # a new barcode may have been scanned for the bin and/or box
      @bin = params[:bin_mdpi_barcode] ? Bin.where(mdpi_barcode: params[:bin_mdpi_barcode]).first : nil
      @box = params[:box_mdpi_barcode] ? Box.where(mdpi_barcode: params[:box_mdpi_barcode]).first : nil

      #if the box (and then bin) are different then validate and save
      unless @box.nil? || (@box == @physical_object.box)
        if @box.full?
          @physical_object.errors[:box] = "Cannot pack this Physical Object in Box <i>#{@box.mdpi_barcode}</i>. It is full!".html_safe
        else
          @physical_object.box = @box
          @physical_object.current_workflow_status = "Boxed"
        end
      end
      unless @bin.nil? || (@bin == @physical_object.bin)
        if @bin.workflow_statuses.last.past_or_equal_status?("Sealed")
          @physical_object.errors[:bin] = "Cannot assign this Physical Object to Bin <i>#{@bin.identifier}</i>. It is sealed or further in the workflow.".html_safe
        else
          @physical_object.bin = @bin
          @physical_object.current_workflow_status = "Binned"
        end
      end
    end

    # redirect logic for returning to pack_list action
    def packing_redirect
    end
    
    # helper for re-rendering pick list if updating failed in some way
    def init_picklist_params
      @picklist = @physical_object.picklist
      @box = @physical_object.box
      @bin = @physical_object.bin
      @edit_mode = true
      @picklisting = true
      @display_assigned = true
    end

end
