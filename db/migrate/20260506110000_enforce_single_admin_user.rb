class EnforceSingleAdminUser < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      CREATE UNIQUE INDEX index_admin_users_singleton ON admin_users ((true));
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX index_admin_users_singleton;
    SQL
  end
end
