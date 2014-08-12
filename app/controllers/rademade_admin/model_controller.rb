# -*- encoding : utf-8 -*-
module RademadeAdmin
  class ModelController < RademadeAdmin::AbstractController

    extend RademadeAdmin::ModelOptions

    include RademadeAdmin::InstanceOptions
    include RademadeAdmin::Templates
    include RademadeAdmin::Notifier

    before_filter :load_options
    before_filter :sortable_service, :only => [:index]

    def create
      authorize! :create, model_class
      saver = RademadeAdmin::Saver.new(model_info, params)
      saver.create_model
      if saver.save_model
        saver.save_aggregated_data
        @item = saver.item
        success_insert @item
      else
        render_errors saver.errors
      end
    end

    def update
      authorize! :update, model_class
      saver = RademadeAdmin::Saver.new(model_info, params)
      if saver.update_model
        saver.save_aggregated_data
        @item = saver.item
        success_update @item
      else
        render_errors saver.errors
      end
    end

    def destroy
      authorize! :destroy, model_class
      @item = model.find(params[:id])
      @item.delete if @item
      success_delete @item
    end

    def autocomplete
      authorize! :read, model_class
      conditions = Search::Conditions::Autocomplete.new(params, model_info.fields)
      @items = Search::Searcher.new(model_info).search(conditions)
      render :json => Autocomplete::BaseSerializer.new(@items)
    end

    def index
      authorize! :read, model_class
      list_breadcrumbs

      #Filter
      conditions = Search::Conditions::List.new(params, model_info.fields)
      @items = Search::Searcher.new(model_info).search(conditions)

      respond_to do |format|
        format.html { render_template }
        format.json { render :json => @items }
      end
    end

    def new
      authorize! :create, model_class
      new_breadcrumbs

      @item = model.new
      render_template
    end

    def edit
      authorize! :update, model_class
      @item = model.find(params[:id])

      edit_breadcrumbs
      render_template
    end

    def related
      authorize! :read, model_class

      related_model = model_info.relations.relation(params[:relation]).to
      @related_model_info = RademadeAdmin::Model::Graph.instance.model_info(related_model)

      @item = model.find(params[:id])
      conditions = Search::Conditions::RelatedList.new(@item, params, @related_model_info.fields)
      @items = Search::Searcher.new(@related_model_info).search(conditions)

      @sortable_service = RademadeAdmin::SortableService.new(@related_model_info, params)

      respond_to do |format|
        format.html {
          related_breadcrumbs
          render_template
        }
        format.json { render :json => Autocomplete::BaseSerializer.new(@items) }
      end
    end

    def related_add
      @item = model.find(params[:id])
      linker = Linker.new(model_info, @item, params[:relation])
      linker.link(params[:related_id])
      success_link
    end

    def related_destroy
      @item = model.find(params[:id])
      linker = Linker.new(model_info, @item, params[:relation])
      linker.unlink(params[:related_id])
      success_link
    end

    def show
      authorize! :read, model_class
      @item = model.find(params[:id])
      respond_to do |format|
        format.html { redirect_to :action => 'index' }
        format.json { render :json => @item }
      end
    end

    def form
      authorize! :read, model_class
      @item = params[:id].blank? ? model.new : model.find(params[:id])
      render form_template_path(true), :layout => false
    end

    def sort
      sortable_service.sort_items
      success_action
    end

    protected

    def model
      @model ||= model_info.model
    end

    def render_template(template = action_name)
      render abstract_template(template)
    end

    def sortable_service
      @sortable_service ||= RademadeAdmin::SortableService.new(model_info, params)
    end

  end
end
