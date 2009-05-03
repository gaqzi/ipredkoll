require 'amalgalite'

module IPREDkoll
  class DB
    def initialize
      @@db = Amalgalite::Database.new(Config.db)
      create_database unless File.size(Config.db) > 0

      if block_given?
        begin
          yield self
        ensure
          disconnect()
        end
      end
    end

    def disconnect
      @@db.close
    end
    alias :close :disconnect

    def ip_active?(ip)
      @@db.execute('SELECT id FROM ips WHERE ip = ? AND end_time IS NULL', ip).flatten
    end

    def mark_ip(ip)
      active = ip_active?(ip)

      if not active.empty?
        @@db.execute("UPDATE ips SET last_seen = datetime('now', 'localtime')
                          WHERE id = ? ", active[0])
      else
        @@db.transaction do |db|
          db.execute("UPDATE ips SET end_time = datetime('now', 'localtime'),
                                    last_seen = datetime('now', 'localtime') WHERE end_time IS NULL")
          db.execute("INSERT INTO ips (ip, start_time, last_seen)
                          VALUES (?, datetime('now', 'localtime'), datetime('now', 'localtime'))", ip)
        end
      end
    end

    def any_ip_under_inspection?
      @@db.execute('SELECT ip, start_time, end_time, last_seen, time_active, case_number, url
                        FROM my_ips_under_inspection')
    end

    def mark_ip_as_notified(ip)
      @@db.execute('UPDATE ipredkoll_ips SET notified = 1 WHERE ip = ?', ip)
    end

    private
    def create_database
      @@db.execute_batch("
        CREATE TABLE ips (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ip VARCHAR(39) NOT NULL,
          start_time VARCHAR(19) NOT NULL,      -- As seconds from epoch
          last_seen  VARCHAR(19) NOT NULL,
          end_time   VARCHAR(19) DEFAULT NULL
        );

        CREATE TABLE ipredkoll_ips (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ip VARCHAR(39) NOT NULL,
          time_active VARCHAR(19) NOT NULL,     -- As seconds from epoch
          case_number VARCHAR(255),
          url VARCHAR(1000),
          notified INTEGER DEFAULT 0
        );

        CREATE TABLE version (version INTEGER NOT NULL); -- Schema version
        INSERT INTO version (version) VALUES (1);

        CREATE VIEW my_ips_under_inspection AS
          SELECT ik.ip AS ip, ips.last_seen AS last_seen, ik.time_active AS time_active,
            ik.case_number AS case_number, ik.url AS url, ips.start_time AS start_time,
            ips.end_time AS end_time
            FROM ips
             INNER JOIN ipredkoll_ips AS ik ON ik.ip = ips.ip
            WHERE ik.notified = 0
              AND (time_active BETWEEN ips.start_time AND IFNULL(ips.end_time, datetime('now', 'localtime')));")
    end # end create_db
  end # End DB
end
