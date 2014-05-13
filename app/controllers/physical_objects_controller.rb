class PhysicalObjectsController < ApplicationController
  
  helper :all

  def new
    # we instantiate an new object here because rails will pick up any default values assigned
    # by the database and the form will be prepopulated with those values
    # we can also pass a hash to PhysicalObject.new({iucat_barcode => 123436}) to assign defaults programmatically
    @physical_object = PhysicalObject.new
    #default format for now
    format = PhysicalObject.formats["Open Reel Tape"]
    @physical_object.format = format
    @tm = @physical_object.create_tm(format)
    @digital_files = []
    @formats = PhysicalObject.formats
    @edit_mode = true
    @action = "create"
    @submit_text = "Create Physical Object"
    @display_assigned = false
  end

  def create
    puts(params.to_yaml)
    @physical_object = PhysicalObject.new(physical_object_params)
    @tm = @physical_object.create_tm(@physical_object.format)
    @tm.physical_object = @physical_object
    if @physical_object.save and @tm.update_attributes(tm_params)
      flash[:notice] = "Physical Object was successfully created.".html_safe
      redirect_to(:action => 'index')
    else
      @edit_mode = true
      render('new')
    end
  end

  def index
    @physical_objects = PhysicalObject.all
  end

  def show
    @edit_mode = false;
    @display_assigned = true
    @physical_object = PhysicalObject.find(params[:id])
    @digital_files = @physical_object.digital_files
    @technical_metadatum = @physical_object.technical_metadatum.as_technical_metadatum
  end

  def edit
    @action = 'update'
    @edit_mode = true
    @physical_object = PhysicalObject.find(params[:id])
    @tm = @physical_object.technical_metadatum.as_technical_metadatum
    @digital_files = @physical_object.digital_files
    @display_assigned = true
    if @physical_object.technical_metadatum.nil?
      flash[:notice] = "A physical object was created without specifying its technical metadatum..."
      redirect_to(action: 'show', id: @physical_object.id)
    else
      @technical_metadatum = @physical_object.technical_metadatum.as_technical_metadatum  
    end
  end

  def update
    puts(params.to_yaml)    
    @physical_object = PhysicalObject.find(params[:id])
    old_format = @physical_object.format
    if ! @physical_object.update_attributes(physical_object_params)
      @edit_mode = true
      render action: :edit
    else
      # format change requires deleting the old technical_metadatum and creating a new one
      if old_format != params[:physical_object][:format]
        @physical_object.technical_metadatum.destroy
        tm = @physical_object.create_tm(@physical_object.format)
        tm.physical_object = @physical_object
        tm.update_attributes(tm_params)
        tm.save
      else
        tm = @physical_object.technical_metadatum.as_technical_metadatum
        tm.update_attributes(tm_params)
        tm.save
      end
      flash[:notice] = "Physical Object successfully updated".html_safe
      redirect_to(action: 'index')
    end
  end

  def destroy
    po = PhysicalObject.find(params[:id])
    if ! po.technical_metadatum.nil?
      po.technical_metadatum.destroy
    end
    po.destroy
    flash[:notice] = "Physical Object was successfully deleted.".html_safe
    redirect_to physical_objects_path
  end
  
  def split_show
    @physical_object = PhysicalObject.find(params[:id]);
    @technical_metadatum = @physical_object.technical_metadatum.as_technical_metadatum
    @digital_files = @physical_object.digital_files
    @count = 0;
    @display_assigned = true
  end
  
  def split_update
    if  params[:count].to_i > 1
      container = Container.new
      container.save
      template = PhysicalObject.find(params[:id])
      template.carrier_stream_index = 1
      template.container_id = container.id
      template.save

      (params[:count].to_i - 1).times do |i|
        po = template.dup
        po.carrier_stream_index = i + 2
        po.container_id = container.id
        tm = template.technical_metadatum.as_technical_metadatum.dup
        tm.physical_object = po
        tm.save
        po.save
      end
      flash[:notice] = "<i>#{template.title}</i> was successfully split into #{params[:count]} records.".html_safe
    end
    redirect_to({:action => 'index'})
  end
  
  def upload_show
    @physical_object = PhysicalObject.new
  end
  
  def upload_update
    if params[:physical_object].nil?
      flash[:notice] = "Please specify a file to upload"
      redirect_to(action: 'upload_show')
    else
      path = params[:physical_object][:csv_file].path
      added = PhysicalObjectsHelper.parse_csv(path)
      flash[:notice] = "#{added['succeeded'].size} records were successfully imported.".html_safe
      if added['failed'].size > 0
        @failed = added['failed']
      end
    end
  end

  def get_tm_form
    f = params[:format]
    id = params[:id]
    @edit_mode = true
    @physical_object = params[:id] == '0' ? PhysicalObject.new : PhysicalObject.find(params[:id])
    if ! @physical_object.technical_metadatum.nil?
      @technical_metadatum = @physical_object.technical_metadatum.as_technical_metadatum
    else
      tm = TechnicalMetadatum.new
      @tm = @physical_object.create_tm(f)
      @physical_object.technical_metadatum = tm
      tm.as_technical_metadatum = @tm
    end
    
    if f == "Open Reel Tape"
      render(partial: 'technical_metadatum/show_open_reel_tape_tm')
    elsif f == "CD-R"
      render(partial: 'technical_metadatum/show_cdr_tm')
    elsif f == "DAT"
      render(partial: 'technical_metadatum/show_dat_tm')
    end
  end
end
