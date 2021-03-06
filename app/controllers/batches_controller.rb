class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :edit, :update, :destroy, :workflow_history, :add_bin, :list_bins]

  def index
    @batches = Batch.all
  end

  def new
    @batch = Batch.new
  end

  def create
    @batch = Batch.new(batch_params)
    if @batch.save
      flash[:notice] = "<i>#{@batch.identifier}</i> was successfully created".html_safe
      redirect_to(:action => 'index')
    else 
      render('new')
    end
  end

  def edit
    @bins = @batch.bins
  end

  def update
    @bins = @batch.bins
    @available_bins = Bin.available_bins
    Batch.transaction do
      if @batch.update_attributes(batch_params)
        flash[:notice] = "<i>#{@batch.identifier}</i> was successfully updated.".html_safe
        redirect_to(:action => 'show', :id => @batch.id)
      else
        render('show')
      end
    end
  end

  def show
    @available_bins = Bin.available_bins
    @bins = @batch.bins
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def destroy
    if @batch.destroy
      flash[:notice] = "<i>#{@batch.identifier}</i> successfully destroyed".html_safe
      redirect_to(:action => 'index')
    else
      flash[:notice] = '<b class="warning">Unable to delete this Batch</b>'.html_safe
      render('show', id: @batch.id)
    end
  end

  def workflow_history
    @workflow_statuses = @batch.workflow_statuses
  end

  def add_bin
    if @batch.packed_status?
      flash[:warning] = Batch.packed_status_message
    elsif params[:bin_ids].nil? or params[:bin_ids].empty?
      flash[:notice] = "No bins were selected to add."
    else
      Batch.transaction do
        params[:bin_ids].each do |b|
          bin = Bin.find(b)
          bin.update_attributes(batch_id: @batch.id, current_workflow_status: "Batched")
        end
      end
      flash[:notice] = "The selected bins were successfully added."
    end
    redirect_to(action: 'show', id: @batch.id)
  end

  def list_bins
    request.format = :xls
    response.headers['Content-Disposition'] = 'attachment; filename="batch_' + @batch.id.to_s + '_list_bins.xls"'
    respond_to do |format|
      format.xls
    end
  end

  private
    def batch_params
      params.require(:batch).permit(:identifier, :description, :destination, :current_workflow_status)
    end

    def set_batch
      # remove batch_ prefix, if present, for csv and xls requests
      @batch = Batch.eager_load(:bins).find(params[:id].to_s.sub(/^batch_/, ''))
    end
  
end
