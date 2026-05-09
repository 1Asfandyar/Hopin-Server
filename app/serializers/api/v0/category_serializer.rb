module Api::V0
  class CategorySerializer < Blueprinter::Base
    identifier :id

    fields :name, :category_type, :user_id, :created_at, :updated_at
  end
end
