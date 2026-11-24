namespace :odsa_user_time_tracking do
  desc "Consolidate prior-day staged OpenDSA user time tracking rows into the main table"
  task consolidate: :environment do
    cutoff_date = ENV["CUTOFF_DATE"].presence || Date.current.strftime("%Y%m%d")
    result = OdsaUserTimeTrackingConsolidator.new(cutoff_date: cutoff_date).consolidate!
    puts "Processed #{result.groups_processed} grouped records and deleted #{result.rows_deleted} staging rows."
  end
end
