# == Schema Information
#
# Table name: terms
#
#  id         :bigint           not null, primary key
#  season     :bigint           not null
#  starts_on  :date             not null
#  ends_on    :date             not null
#  year       :bigint           not null
#  created_at :datetime
#  updated_at :datetime
#  slug       :string(255)      not null
#
# Indexes
#
#  index_terms_on_slug             (slug) UNIQUE
#  index_terms_on_starts_on        (starts_on)
#  index_terms_on_year_and_season  (year,season)
#
ActiveAdmin.register Term, sort_order: :created_at_asc do
  menu parent: 'University-oriented', priority: 10
  permit_params :year, :starts_on, :ends_on, :season
  actions :all, except: [:destroy, :edit]

  index do
    id_column
    column 'Season', :season_name
    column :year
    column :starts_on
    column :ends_on
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :season, as: :radio, collection: Term::SEASONS
      f.input :year
      f.input :starts_on, as: :datepicker
      f.input :ends_on, as: :datepicker
    end
    f.actions
  end

  sidebar 'Course Offerings', only: :show do
    table_for term.course_offerings do
      column(:course) do |c|
        link_to c.course.number_and_org, admin_course_path(c.course)
      end
      column(:label) { |c| link_to c.label, admin_course_offering_path(c) }
    end
  end

end
