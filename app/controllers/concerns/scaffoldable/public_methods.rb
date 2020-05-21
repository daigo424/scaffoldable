# frozen_string_literal: true

module Scaffoldable
  module PublicMethods
    def index
      call_hook :index_before_override
      process_index
      after_index
      call_hook :index_after_override
      render_index
    end

    def show
      call_hook :show_before_override
      after_show
      call_hook :show_after_override
      render_show
    end

    def new
      call_hook :new_before_override
      process_new
      after_new
      call_hook :new_after_override
      render_new
    end

    def edit
      call_hook :edit_before_override
      call_hook :edit_after_override
      render_edit
    end

    def create
      process_create
    end

    def update
      process_update
    end

    def destroy
      process_destroy
    end

    def process_new
      new_model_instance
      # ユーザーIDを設定
      set_relation_model_instance
    end

    def ransack_search(search_model, ransack_params)
      @search = search_model.ransack
      return nil if ransack_params.blank?
      ransack_params = if search_model.try(:ransack_params, ransack_params)
                         search_model.ransack_params(ransack_params)
                       else
                         ransack_params
                       end
      ransack_params.try(:merge, ransack_base_params) if try(:ransack_base_params)
      @search = search_model.ransack(ransack_params)
      @search.result
    end

    def process_index
      self.resources = ransack_search(search_model, params[:q])
      self.resources = index_resources if resources.nil?
      self.resources = resources_wheres
      self.resources = resources_order
      self.resources = resources_paginate if paging?
      if call_hook?(:resources_includes_override)
        self.resources = call_hook(:resources_includes_override)
      else
        self.resources = resources.includes(*resources_includes) if resources_includes.present?
      end
      if call_hook?(:resources_references_override)
        self.resources = call_hook(:resources_references_override)
      else
        self.resources = resources.references(*resources_references) if resources_references.present?
      end
      to_model_instances(resources)
    end

    def process_create
      call_hook(:create_before_override)
      new_model_instance(controller_params)

      # ユーザーIDを設定
      set_relation_model_instance

      if model_instance_create
        call_hook(:create_successed_override)
        after_succeeded_creating
        render_succeeded_creating
      else
        call_hook(:create_failed_override)
        after_failed_creating
        render_failed_creating
      end
    end

    def model_instance_create
      model_instance.save
    end

    def model_instance_update
      model_instance.update(controller_params)
    end

    def render_succeeded_creating
      respond_to do |format|
        format.html do
          flash[:notice] = message_create_successed if message_create_successed.present?
          if call_hook?(:create_succeeded_render_override)
            call_hook(:create_succeeded_render_override)
          else
            if url_after_creating.try(:to_sym) == :back
              redirect_back(
                fallback_location: index_path
              )
            else
              redirect_to(
                url_after_creating
              )
            end
          end
        end
        format.json { render json: model_instance, status: :ok }
        format.js { render_succeeded_creating_by_js(status: :ok, content_type: "application/json") }
      end
    end

    def render_failed_creating
      respond_to do |format|
        format.html do
          flash[:alert] = message_create_failed if message_create_failed.present?
          render_new
        end
        format.json { render json: model_instance.errors.full_messages, status: :unprocessable_entity }
        format.js { render_failed_creating_by_js(status: :unprocessable_entity, content_type: "application/json") }
      end
    end

    def process_update
      call_hook(:update_before_override)
      if model_instance_update
        after_succeeded_updating
        call_hook(:update_successed_override)
        render_succeeded_updating
      else
        after_failed_updating
        call_hook(:update_failed_override)
        render_failed_updating
      end
    end

    def render_succeeded_updating
      respond_to do |format|
        format.html do
          flash[:notice] = message_update_successed if message_update_successed.present?
          if call_hook?(:update_succeeded_render_override)
            call_hook(:update_succeeded_render_override)
          else
            if url_after_updating.try(:to_sym) == :back
              redirect_back(
                fallback_location: index_path
              )
            else
              redirect_to(
                url_after_updating
              )
            end
          end
        end
        format.json { render json: model_instance, status: :ok }
        format.js { render_succeeded_updating_by_js(status: :ok, content_type: "application/json") }
      end
    end

    def render_failed_updating
      respond_to do |format|
        format.html do
          flash[:alert] = message_update_failed if message_update_failed.present?
          render_edit
        end
        format.json { render json: model_instance.errors.full_messages, status: :unprocessable_entity }
        format.js { render_failed_updating_by_js(status: :unprocessable_entity, content_type: "application/json") }
      end
    end

    def process_destroy
      call_hook(:destroy_before_override)
      if model_instance_destroy_valid?
        call_hook(:destroy_successed_override)
        render_succeeded_destroying
      else
        call_hook(:destroy_failed_override)
        render_failed_destroying
      end
    end

    def render_succeeded_destroying
      notice = message_destroy_successed if message_destroy_successed.present?
      model_instance_destroy
      respond_to do |format|
        format.html do
          flash[:notice] = notice
          if call_hook?(:destroy_succeeded_render_override)
            call_hook(:destroy_succeeded_render_override)
          else
            if url_after_destroyed.try(:to_sym) == :back
              redirect_back(
                fallback_location: index_path
              )
            else
              redirect_to(
                url_after_destroyed
              )
            end
          end
        end
        format.json { render json: model_instance, status: :ok }
        format.js { render_succeeded_updating_by_js(status: :ok, content_type: "application/json") }
      end
    end

    def render_failed_destroying
      respond_to do |format|
        format.html do
          flash[:alert] = message_destroy_failed if message_destroy_failed.present?
          redirect_to(
            url_after_failed_destroyed
          )
        end
        format.json { render json: model_instance.errors.full_messages, status: :unprocessable_entity }
        format.js { render_failed_updating_by_js(status: :unprocessable_entity, content_type: "application/json") }
      end
    end
  end
end
