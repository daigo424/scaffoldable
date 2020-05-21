# frozen_string_literal: true

module Scaffoldable
  module Base
    def regist_override(name, proc)
      instance_variable_set(:"@#{name}", proc)
      @overrides = {} unless @overrides
      @overrides[:"@#{name}"] = proc
    end

    def inherited(klass)
      @overrides = {} unless @overrides
      klass.instance_variable_set(:@overrides, {}) unless klass.instance_variable_get(:@overrides)
      klass.instance_variable_set(:@overrides, klass.instance_variable_get(:@overrides).merge(@overrides))
      @overrides.each do |key, proc|
        klass.instance_variable_set(key, proc)
      end
    end

    def scaffoldable_resources_override(options = {}, name)
      return unless options[:index].key?(name)
      if options[:index][name].is_a?(Proc)
        regist_override(:"resources_#{name}_override", options[:index][name])
      elsif options[:index][name].is_a?(Array)
        regist_override(:"resources_#{name}_override", proc { resources.send("#{name}", options[:index][name]) })
      end
    end

    def scaffoldable_to_path(object)
      return object if object.is_a?(Proc)
      return proc { send(object) } if object.is_a?(String)
      return proc { send(object) } if object.is_a?(Symbol)
    end

    def scaffoldable_cud_define(options = {}, action)
      return unless options[action].is_a?(Hash)
      if options[action].key?(:succeeded_render)
        regist_override(:"#{action}_succeeded_render_override", options[action][:succeeded_render])
      end

      if options[action].key?(:succeeded_path)
        regist_override(:"#{action}_succeeded_path_override", scaffoldable_to_path(options[action][:succeeded_path]))
      end

      if options[action].key?(:succeeded_message)
        message = options[action][:succeeded_message]
        regist_override(:"#{action}_succeeded_message_override", message.is_a?(Proc) ? message : proc { message })
      end

      if options[action].key?(:failed_message)
        message = options[action][:failed_message]
        regist_override(:"#{action}_failed_message_override", message.is_a?(Proc) ? message : proc { message })
        message = message.call if message.is_a?(Proc)
      end
    end

    def scaffoldable_model_override(options = {})
      if options[:model].is_a?(Proc)
        regist_override(:"model_override", options[:model])
      elsif options[:model].try(:new).is_a?(ActiveRecord::Base)
        regist_override(:"model_override", proc { options[:model] })
      elsif options[:model].is_a?(Hash)
        options[:model].each do |action, model|
          regist_override(:"#{action}_model_override", proc { model })
        end
      else
        return
      end
    end

    def scaffoldable_name_action_define(options = {}, action, name)
      return unless options.key?(action)
      if options[action][name].is_a?(Proc)
        regist_override(:"#{action}_#{name}_override", options[action][name])
      end
    end

    def scaffoldable_default_model_params_define(options = {}, action)
      return unless options.key?(action)
      if options[action][:default_model_params].is_a?(Hash)
        regist_override(:"#{action}_default_model_params_override", proc { options[action][:default_model_params] })
      elsif options[action][:default_model_params].is_a?(Proc)
        regist_override(:"#{action}_default_model_params_override", options[action][:default_model_params])
      end
    end

    def scaffoldable_index(options = {})
      return unless options[:index].is_a?(Hash)
      scaffoldable_resources_override(options, :order)
      scaffoldable_resources_override(options, :where)
      scaffoldable_resources_override(options, :includes)
      scaffoldable_resources_override(options, :references)
      scaffoldable_resources_override(options, :paginate)
      if options[:index][:paginate].present? && options[:index][:paginate].is_a?(Hash)
        if options[:index][:paginate][:per].is_a?(Integer)
          regist_override(:"resources_paginate_override", proc { resources.page(params[:page]).per(options[:index][:paginate][:per]) })
        end
      elsif options[:index][:paginate].is_a?(FalseClass)
        regist_override(:"resources_paginate_override", proc { resources })
      end
    end

    def find_model_instance_override(options = {})
      if options[:find].is_a?(Proc)
        regist_override(:"find_model_instance_override", options[:find])
      elsif options[:find].is_a?(Symbol) || options[:find].is_a?(String)
        regist_override(:"find_model_instance_override", send(options[:find]))
      end
    end

    def new_model_instance_override(options = {})
      if options[:new_model_instance].is_a?(Proc)
        regist_override(:"new_model_instance_override", options[:new_model_instance])
      end
    end

    def scaffoldable_config(options = {})
      find_model_instance_override(options)
      new_model_instance_override(options)
      scaffoldable_name_action_define(options, :show, :before)
      scaffoldable_name_action_define(options, :show, :after)
      scaffoldable_name_action_define(options, :index, :before)
      scaffoldable_name_action_define(options, :index, :after)
      scaffoldable_name_action_define(options, :new, :before)
      scaffoldable_name_action_define(options, :new, :after)
      scaffoldable_name_action_define(options, :edit, :before)
      scaffoldable_name_action_define(options, :edit, :after)
      scaffoldable_name_action_define(options, :create, :before)
      scaffoldable_name_action_define(options, :create, :successed)
      scaffoldable_name_action_define(options, :create, :failed)
      scaffoldable_name_action_define(options, :update, :before)
      scaffoldable_name_action_define(options, :update, :successed)
      scaffoldable_name_action_define(options, :update, :failed)
      scaffoldable_name_action_define(options, :destroy, :before)
      scaffoldable_name_action_define(options, :destroy, :successed)
      scaffoldable_name_action_define(options, :destroy, :failed)

      scaffoldable_index(options)
      %i[create update destroy].each do |action|
        scaffoldable_cud_define(options, action)
      end
      %i[index show new edit create update destroy].each do |action|
        scaffoldable_default_model_params_define(options, action)
        scaffoldable_name_action_define(options, action, :model)
      end
    end

    def scaffoldable(options = {})
      include ::Scaffoldable::Helper

      before_action :set_form_columns_method_name
      before_action :set_model
      before_action :set_model_instance, only: %i[show edit update destroy].freeze
      before_action :auth_check, only: %i[show edit update destroy].freeze
      before_action :set_search_params, only: %i[index]

      include ::Scaffoldable::PublicMethods
      include ::Scaffoldable::PrivateMethods

      find_model_instance_override(options)
      new_model_instance_override(options)
      scaffoldable_name_action_define(options, :show, :before)
      scaffoldable_name_action_define(options, :show, :after)
      scaffoldable_name_action_define(options, :index, :before)
      scaffoldable_name_action_define(options, :index, :after)
      scaffoldable_name_action_define(options, :new, :before)
      scaffoldable_name_action_define(options, :new, :after)
      scaffoldable_name_action_define(options, :edit, :before)
      scaffoldable_name_action_define(options, :edit, :after)
      scaffoldable_name_action_define(options, :create, :before)
      scaffoldable_name_action_define(options, :create, :successed)
      scaffoldable_name_action_define(options, :create, :failed)
      scaffoldable_name_action_define(options, :update, :before)
      scaffoldable_name_action_define(options, :update, :successed)
      scaffoldable_name_action_define(options, :update, :failed)
      scaffoldable_name_action_define(options, :destroy, :before)
      scaffoldable_name_action_define(options, :destroy, :successed)
      scaffoldable_name_action_define(options, :destroy, :failed)
      scaffoldable_index(options)
      %i[create update destroy].each do |action|
        scaffoldable_cud_define(options, action)
      end
      %i[index show new edit create update destroy].each do |action|
        scaffoldable_default_model_params_define(options, action)
        scaffoldable_name_action_define(options, action, :model)
      end
      scaffoldable_model_override(options)
    end
  end
end
