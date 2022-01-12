import covid19.datasource as ds;

public isolated distinct service class CovidData {
    private final readonly & ds:CovidEntry entryRecord;

    isolated function init(ds:CovidEntry entryRecord) {
        self.entryRecord = entryRecord.cloneReadOnly();
    }

    isolated resource function get isoCode() returns string {
        return self.entryRecord.isoCode;
    }

    isolated resource function get country() returns string {
        return self.entryRecord.country;
    }

    isolated resource function get cases() returns decimal? {
        return self.entryRecord.cases;
    }

    isolated resource function get deaths() returns decimal? {
        return self.entryRecord.deaths;
    }

    isolated resource function get recovered() returns decimal? {
        return self.entryRecord.recovered;
    }

    isolated resource function get active() returns decimal? {
        return self.entryRecord.active;
    }
}
