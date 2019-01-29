module DataAnon
  module Strategy
    class Blacklist < DataAnon::Strategy::Base

      def process_record index, record
        updates = {}
        @fields.each do |field, strategy|
          database_field_name = record.attributes.select { |k,v| k == field }.keys[0]
          field_value = record.attributes[database_field_name]
          unless field_value.nil? || is_primary_key?(database_field_name)
            field = DataAnon::Core::Field.new(database_field_name, field_value, index, record, @name)
            updates[database_field_name] = strategy.anonymize(field)
          end
        end
        if updates.any?
          if bulk_process?
            record.assign_attributes(updates)
            collect_for_bulk_process(record)
          else
            record.update_columns(updates)
          end
        end
      end

      def bulk_store(records)
        columns = @fields.keys
        if source_table.respond_to? :ar_import
          source_table.ar_import @primary_keys + columns, records, validate: false, on_duplicate_key_update: columns
        else
          source_table.import @primary_keys + columns, records, validate: false, on_duplicate_key_update: columns
        end
      end

    end
  end
end
