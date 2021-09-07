# == Schema Information
#
# Table name: inst_books
#
#  id                 :bigint           not null, primary key
#  course_offering_id :bigint
#  user_id            :bigint           not null
#  title              :string(50)       not null
#  created_at         :datetime
#  updated_at         :datetime
#  template           :boolean          default(FALSE)
#  desc               :string(255)
#  last_compiled      :datetime
#  options            :text(4294967295)
#  book_type          :bigint
#
# Indexes
#
#  inst_books_course_offering_id_fk  (course_offering_id)
#  inst_books_user_id_fk             (user_id)
#
require 'rails_helper'

RSpec.describe InstBook, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
