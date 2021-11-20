# == Schema Information
#
# Table name: odsa_book_progresses
#
#  id                   :bigint           not null, primary key
#  user_id              :bigint           not null
#  inst_book_id         :bigint           not null
#  started_exercises    :text(4294967295) not null
#  proficient_exercises :text(4294967295) not null
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_odsa_book_progresses_on_user_id_and_inst_book_id  (user_id,inst_book_id) UNIQUE
#  odsa_book_progresses_inst_book_id_fk                    (inst_book_id)
#
require 'rails_helper'

RSpec.describe OdsaBookProgress, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
