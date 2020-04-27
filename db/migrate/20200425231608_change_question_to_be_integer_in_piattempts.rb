class ChangeQuestionToBeIntegerInPiattempts < ActiveRecord::Migration
  def change
    change_column :pi_attempts, :question, :integer
  end
end
