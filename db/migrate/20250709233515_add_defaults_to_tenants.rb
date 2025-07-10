class AddDefaultsToTenants < ActiveRecord::Migration[8.0]
  def change
    change_column_default :tenants, :plan, 'trial'
    change_column_default :tenants, :settings, {}

    # Set trial_ends_at for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE tenants#{' '}
          SET trial_ends_at = created_at + interval '14 days'#{' '}
          WHERE trial_ends_at IS NULL
        SQL
      end
    end
  end
end
