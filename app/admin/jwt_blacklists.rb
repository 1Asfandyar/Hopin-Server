ActiveAdmin.register JwtBlacklist do
  menu false

  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :jti
    column :exp
    column :created_at
    actions
  end

  filter :jti
  filter :exp
  filter :created_at
end
