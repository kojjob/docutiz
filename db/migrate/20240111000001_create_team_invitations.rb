class CreateTeamInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :team_invitations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :name
      t.string :role, default: "member"
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.references :user, foreign_key: true # Set when invitation is accepted

      t.timestamps
    end

    add_index :team_invitations, :token, unique: true
    add_index :team_invitations, [:tenant_id, :email], where: "accepted_at IS NULL"
    add_index :team_invitations, :expires_at
  end
end