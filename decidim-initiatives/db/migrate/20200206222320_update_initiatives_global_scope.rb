# frozen_string_literal: true

class UpdateInitiativesGlobalScope < ActiveRecord::Migration[5.2]
  def change
    Decidim::InitiativesType.where(only_global_scope_enabled: true).each do |type|
      # will trigger update_global_scope if needed
      type.save
    end
  end
end
