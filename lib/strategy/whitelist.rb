module DataAnon
  module Strategy
    class Whitelist < DataAnon::Strategy::Base

      def self.whitelist?
        true
      end

      def process_record(index, record)
        dest_record_map = {}
        record.attributes.each do |field_name, field_value|
          unless field_value.nil? || is_primary_key?(field_name)
            field = DataAnon::Core::Field.new(field_name, field_value, index, record, @name)
            field_strategy = @fields[field_name] || default_strategy(field_name)
            dest_record_map[field_name] = field_strategy.anonymize(field)
          end
        end
        dest_record = dest_table.new dest_record_map
        @primary_keys.each do |key|
          dest_record[key] = record[key]
        end
        if bulk_process?
          collect_for_bulk_process(dest_record)
        else
          dest_record.save!
        end
      end

      def bulk_store(records)
        columns = source_table.column_names
        if source_table.respond_to? :ar_import
          source_table.ar_import @primary_keys + columns, records, validate: false, on_duplicate_key_update: columns
        else
          source_table.import @primary_keys + columns, records, validate: false, on_duplicate_key_update: columns
        end
      end

    end
  end
end
