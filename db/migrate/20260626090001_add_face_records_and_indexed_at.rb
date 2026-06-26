# frozen_string_literal: true

# Persists Rekognition indexing results for each user, plus the last successful
# index timestamp on the user record itself.
class AddFaceRecordsAndIndexedAt < ActiveRecord::Migration[8.0]
  def change
    create_table :face_records do |t|
      t.references :user, null: false, foreign_key: true
      t.string :rekognition_face_id, null: false
      t.string :s3_bucket, null: false
      t.string :s3_key, null: false
      t.datetime :indexed_at, null: false
      t.timestamps
    end

    add_index :face_records, :rekognition_face_id, unique: true

    add_column :users, :indexed_at, :datetime
  end
end
