class ChangeQuestionToBeIntegerInPiattempts < ActiveRecord::Migration[5.1]
  def change
    change_column :pi_attempts, :question, :integer
  end
end
