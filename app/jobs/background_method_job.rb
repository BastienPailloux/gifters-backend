# frozen_string_literal: true

class BackgroundMethodJob < ApplicationJob
  queue_as :default

  def perform(model_class, record_id, method_name, args = [], kwargs = {})
    record = model_class.constantize.find(record_id)
    record.public_send(method_name, *args, **kwargs)
  end
end
