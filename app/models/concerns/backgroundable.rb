# frozen_string_literal: true

module Backgroundable
  extend ActiveSupport::Concern

  def method_missing(name, *args, **kwargs, &block)
    if name.to_s.start_with?('background_')
      actual_method = name.to_s.delete_prefix('background_')
      delay = kwargs.delete(:delay)
      if delay
        BackgroundMethodJob.new.set(wait: delay).perform_later(self.class.name, id, actual_method, args, kwargs)
      else
        BackgroundMethodJob.perform_later(self.class.name, id, actual_method, args, kwargs)
      end
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?('background_') || super
  end
end
