# == Schema Information
#
# Table name: inst_books
#
#  id                 :integer          not null, primary key
#  course_offering_id :integer
#  user_id            :integer          not null
#  title              :string(50)       not null
#  created_at         :datetime
#  updated_at         :datetime
#  template           :boolean          default(FALSE)
#  desc               :string(255)
#  last_compiled      :datetime
#  options            :text(4294967295)
#  book_type          :integer
#
# Indexes
#
#  inst_books_course_offering_id_fk  (course_offering_id)
#  inst_books_user_id_fk             (user_id)
#

FactoryBot.define do
  factory :inst_book do
  end
end
