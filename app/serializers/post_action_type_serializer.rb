# frozen_string_literal: true

class PostActionTypeSerializer < ApplicationSerializer
  attributes(:id, :name_key, :name, :description, :short_description, :is_flag, :is_custom_flag)

  include ConfigurableUrls

  def is_custom_flag
    !!PostActionType.custom_types[object.id]
  end

  def is_flag
    !!PostActionType.flag_types[object.id]
  end

  def name
    i18n("title")
  end

  def description
    i18n("description", tos_url: tos_url, base_path: Discourse.base_path)
  end

  def short_description
    i18n("short_description", tos_url: tos_url, base_path: Discourse.base_path)
  end

  def name_key
    PostActionType.types[object.id]
  end

  protected

  def i18n(field, vars = nil)
    key = "post_action_types.#{name_key}.#{field}"
    vars ? I18n.t(key, vars) : I18n.t(key)
  end
end
