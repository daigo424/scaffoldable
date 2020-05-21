# frozen_string_literal: true

module Scaffoldable
  module PrivateMethods
    def model_instance
      instance_variable_get("@#{model.model_name.singular}".to_sym)
    end

    def model_instances
      instance_variable_get("@#{model.model_name.plural}".to_sym)
    end

    def new_model_instance(model_params = nil)
      instance_variable_set(
        "@#{model.model_name.singular}".to_sym,
        new_model(model_params)
      )
    end

    def new_model(model_params = nil)
      new_model_instance = nil
      new_model_instance = call_hook(:"new_model_instance_override") if call_hook?(:"new_model_instance_override")
      if new_model_instance
        new_model_instance.attributes = model_params if model_params.present?
        new_model_instance
      else
        model_params.nil? ? model.new : model.new(model_params)
      end
    end

    def controller_params
      permit_params = model.try(:permit_params)
      model_name = model.model_name.singular
      default_model_params = {}
      default_model_params = call_hook(:"#{action_name}_default_model_params_override") if call_hook?(:"#{action_name}_default_model_params_override")
      return default_model_params.merge(params.require(model_name).permit(permit_params)).with_indifferent_access if permit_params && params.key?(model_name)
      # 定義されていなければ空のハッシュオブジェクトを返す
      return default_model_params.merge({}).with_indifferent_access unless respond_to?("#{model_name}_params", true)
      default_model_params.merge(send("#{model_name}_params")).with_indifferent_access
    end

    def model_instance_create
      model_instance.save
    end

    def model_instance_destroy
      model_instance.destroy
    end

    def model_instance_destroy_valid?
      model_instance.valid?
    end

    def message_create_successed
      message = call_hook(:create_succeeded_message_override) if call_hook?(:create_succeeded_message_override)
      return message if message
      t("flash_messages.create_successed", name: human_readable_now_model_name)
    end

    def message_update_successed
      message = call_hook(:update_succeeded_message_override) if call_hook?(:update_succeeded_message_override)
      return message if message
      t("flash_messages.update_successed", name: human_readable_now_model_name)
    end

    def message_destroy_successed
      message = call_hook(:destroy_succeeded_message_override) if call_hook?(:destroy_succeeded_message_override)
      return message if message
      t("flash_messages.destroy_successed", name: human_readable_now_model_name)
    end

    def message_create_failed
      message = call_hook(:create_failed_message_override) if call_hook?(:create_failed_message_override)
      return message if message
      t("flash_messages.create_failed", name: human_readable_now_model_name)
    end

    def message_update_failed
      message = call_hook(:update_failed_message_override) if call_hook?(:update_failed_message_override)
      return message if message
      t("flash_messages.update_failed", name: human_readable_now_model_name)
    end

    def message_destroy_failed
      message = call_hook(:destroy_failed_message_override) if call_hook?(:destroy_failed_message_override)
      return message if message
      t("flash_messages.destroy_failed", name: human_readable_now_model_name)
    end

    def url_after_failed_destroyed
      index_path
    end

    def relation_model_symbol
      nil
    end

    def call_relation_model
      nil
    end

    def set_relation_model_instance
      return if relation_model_symbol.nil?
      return unless model_instance.has_attribute?(relation_model_symbol) &&
                    model_instance.send(relation_model_symbol).nil?
      return if call_relation_model.nil?
      model_instance.send("#{relation_model_symbol}=", call_relation_model.to_param)
      set_relation_model_instance_id
    end

    def set_relation_model_instance_id
      request.path_info.split("/").reject(&:blank?)[1..-1].each_slice(2) do |resource, id|
        break unless id.match?(/\A\d+\z/)
        break unless model_instance.class.attribute_names.include?("#{resource.singularize}_id")
        model_instance.send("#{resource.singularize}_id=", id.to_i)
      end
    end

    def after_index; end

    def after_show; end

    def after_new; end

    def set_model_instance
      instance = find_model_instance
      return if instance.nil?
      instance_variable_set(
        "@#{model.model_name.singular}".to_sym,
        instance
      )
    rescue StandardError => e
      Rails.logger.debug e
      raise e
    end

    def to_model_instance(resource = nil)
      instance_variable_set(
        "@#{model.model_name.singular}".to_sym,
        resource
      )
    end

    def to_model_instances(resources = nil)
      instance_variable_set(
        "@#{search_model.model_name.plural}".to_sym,
        resources
      )
    end

    def index_resources
      search_model
    end

    def resources
      @resources
    end

    def resources=(value)
      @resources = value
    end

    def resources_includes
      []
    end

    def resources_references
      []
    end

    def resources_wheres
      return call_hook(:resources_where_override) if call_hook?(:resources_where_override)
      return nil if resources.nil?
      resources
    end

    def resources_order
      return call_hook(:resources_order_override) if call_hook?(:resources_order_override)
      return nil if resources.nil?
      resources
    end

    def resources_paginate
      return call_hook(:resources_paginate_override) if call_hook?(:resources_paginate_override)
      return nil if resources.nil?
      self.resources = resources.page(params[:page])
      return resources if resources_per_max.nil?
      resources.per(resources_per_max)
    end

    def resources_per_max
      value = try(:override_paging_per)
      return nil if value.nil?
      value
    end

    def paging?
      is = try(:override_paging?)
      return true if is.nil?
      is
    end

    def action?(*key)
      key.include?(action_name.to_sym)
    end

    def format?(*key)
      key.include?(format_name)
    end

    def format_name
      params[:format].blank? ? :html : params[:format].to_sym
    end

    def find_model_instance
      return call_hook(:find_model_instance_override) if call_hook?(:find_model_instance_override)
      model.find(params[:id])
    end

    def url_after_creating
      path = call_hook(:create_succeeded_path_override) if call_hook?(:create_succeeded_path_override)
      return index_path if path.nil?
      path
    end

    def after_succeeded_creating; end

    def after_failed_creating; end

    def url_after_updating
      path = call_hook(:update_succeeded_path_override) if call_hook?(:update_succeeded_path_override)
      return index_path if path.nil?
      path
    end

    def after_succeeded_updating; end

    def after_failed_updating; end

    def url_after_destroyed
      path = call_hook(:destroy_succeeded_path_override) if call_hook?(:destroy_succeeded_path_override)
      return index_path if path.nil?
      path
    end

    def index_path(options = {})
      url_for({ action: :index }.merge(options))
    end

    def show_path(options = {})
      if begin
            url_for({ action: :show, id: model_instance.to_param }.merge(options))
          rescue StandardError
            false
          end
        url_for({ action: :show, id: model_instance.to_param }.merge(options))
      elsif begin
               url_for({ action: :edit, id: model_instance.to_param }.merge(options))
             rescue StandardError
               false
             end
        url_for({ action: :edit, id: model_instance.to_param }.merge(options))
      else
        url_for({ action: :index }.merge(options))
      end
    end

    def new_path(options = {})
      url_for({ action: :new }.merge(options))
    end

    def edit_path(options = {})
      if begin
            url_for({ action: :edit, id: model_instance.to_param }.merge(options))
          rescue StandardError
            false
          end
        url_for({ action: :edit, id: model_instance.to_param }.merge(options))
      else
        url_for({ action: :index }.merge(options))
      end
    end

    def create_or_update_path(options = {})
      if model_instance.new_record?
        url_for({ action: :create }.merge(options))
      else
        url_for({ action: :update, id: model_instance.to_param }.merge(options))
      end
    end

    def destroy_path(options = {})
      if begin
            url_for({ action: :destroy, id: model_instance.to_param }.merge(options))
          rescue StandardError
            false
          end
        url_for({ action: :destroy, id: model_instance.to_param }.merge(options))
      else
        url_for({ action: :index }.merge(options))
      end
    end

    def render_index(options = {})
      render :index, options
    end

    def render_new(options = {})
      render :new, options
    end

    def render_edit(options = {})
      render :edit, options
    end

    def render_show(options = {})
      render :show, options
    end

    def human_readable_now_model_name
      model.model_name.human
    end

    def model
      return call_hook(:model_override) if call_hook?(:model_override)
      return call_hook(:"#{action_name}_model_override") if call_hook?(:"#{action_name}_model_override")
      controller_name.camelize.singularize.constantize
    end

    def search_model
      model
    end

    def form_columns_method_name
      :form_columns
    end

    def set_model
      @model = model
    end

    def set_form_columns_method_name
      @form_columns_method_name = form_columns_method_name
    end

    def auth_check
      authorize model_instance
    end

    def set_search_params
      @search_params = params.permit!.to_h[:q] if params[:q].present?
    end

    def render_succeeded_creating_by_js(options)
      head options[:status]
    end

    def render_failed_creating_by_js(options)
      head options[:status]
    end

    def render_succeeded_updating_by_js(options)
      head options[:status]
    end

    def render_failed_updating_by_js(options)
      head options[:status]
    end

    def call_hook?(name)
      self.class.instance_variable_defined?(:"@#{name}")
    end

    def call_hook(name)
      if call_hook?(name)
        self.instance_exec(&self.class.instance_variable_get(:"@#{name}"))
      end
    end

    def authorize(showing_record)
      # HINT: レコードの権限チェックを行う。
      # 違反しているならraiseを発生させるか、別のページへリダイレクトさせる
      # 権限チェックを行わない場合は何もしない
    end
  end
end
