class OdsaUserTimeTrackingConsolidator
  Result = Struct.new(:groups_processed, :rows_deleted, keyword_init: true)

  def initialize(cutoff_date: Date.current.strftime("%Y%m%d"))
    @cutoff_date = cutoff_date.to_s
  end

  def consolidate!
    groups_processed = 0
    rows_deleted = 0

    eligible_rows.group_by(&method(:grouping_key)).each_value do |group_rows|
      ActiveRecord::Base.transaction do
        consolidate_group!(group_rows)
        rows_deleted += OdsaUserTimeTrackingStaging.where(id: group_rows.map(&:id)).delete_all
      end
      groups_processed += 1
    end

    Result.new(groups_processed: groups_processed, rows_deleted: rows_deleted)
  end

  private

  def eligible_rows
    OdsaUserTimeTrackingStaging.where("session_date < ?", @cutoff_date).to_a
  end

  def grouping_key(row)
    [row.user_id, row.inst_book_id, row.inst_module_id, row.inst_chapter_id, row.session_date]
  end

  def consolidate_group!(group_rows)
    first = group_rows.first
    merged_row = OdsaUserTimeTracking.find_or_initialize_by(
      user_id: first.user_id,
      inst_book_id: first.inst_book_id,
      inst_module_id: first.inst_module_id,
      inst_chapter_id: first.inst_chapter_id,
      session_date: first.session_date
    )

    merged_row.uuid ||= first.uuid
    merged_row.total_time = merged_total_time(merged_row, group_rows)
    merged_row.sections_time = merged_sections_time(merged_row, group_rows)
    merged_row.save!
  end

  def merged_total_time(existing_row, group_rows)
    prior_total = existing_row.persisted? ? existing_row.total_time.to_f : 0.0
    group_total = group_rows.sum { |row| row.total_time.to_f }
    (prior_total + group_total).round(2)
  end

  def merged_sections_time(existing_row, group_rows)
    section_totals = Hash.new(0.0)

    parse_sections(existing_row.sections_time).each do |name, value|
      section_totals[name] += value
    end

    group_rows.each do |row|
      parse_sections(row.sections_time).each do |name, value|
        section_totals[name] += value
      end
    end

    section_totals.map { |name, value| { name => value.round(2) } }.to_json
  end

  def parse_sections(raw_sections)
    return [] if raw_sections.blank?

    parsed = JSON.parse(raw_sections)
    return [] unless parsed.is_a?(Array)

    parsed.filter_map do |entry|
      next unless entry.is_a?(Hash)

      name, value = entry.first
      next if name.blank?

      [name, value.to_f]
    end
  rescue JSON::ParserError
    []
  end
end
