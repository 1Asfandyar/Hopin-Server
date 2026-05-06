ActiveAdmin.register AdminUser do
  actions :index, :show, :edit, :update
  config.batch_actions = false

  permit_params :email, :password, :password_confirmation

  index do
    id_column
    column :email
    column :created_at
    actions
  end

  filter :email
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  controller do
    def update
      if params.dig(:admin_user, :password).blank?
        params[:admin_user].delete(:password)
        params[:admin_user].delete(:password_confirmation)
      end

      super
    end
  end
end
