# frozen_string_literal: true

class AddMissingIndices < ActiveRecord::Migration[8.0]
  def change
    add_index :face_records, :indexed_at
    add_index :users, :indexed_at
    add_index :users, :created_at
  end
end
