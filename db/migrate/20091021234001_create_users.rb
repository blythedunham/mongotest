class CreateUsers < ActiveRecord::Migration
  def self.up
      create_table "users", :force => true do |t|
        t.string   "uuid",                  :limit => 36,                    :null => false
        t.string   "username",              :limit => 20,                    :null => false
        t.string   "email"
        t.string   "crypted_password"
        t.string   "password_salt"
        t.string   "persistence_token"
        t.integer  "login_count"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean  "accepted_terms_of_use",               :default => false, :null => false
    end
  end

  def self.down
    drop_table :users
  end
end
