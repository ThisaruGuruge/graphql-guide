isolated table<CovidEntry> key(isoCode) covidEntriesTable = table [
    {isoCode: "AFG", country: "Afghanistan", cases: 10000, deaths: 500, recovered: 1500, active: 8000},
    {isoCode: "SL", country: "Sri Lanka", cases: 20000, deaths: 1000, recovered: 4000, active: 15000},
    {isoCode: "US", country: "United States", cases: 40000, deaths: 5000, recovered: 15000, active: 20000}
];

public isolated function getAllEntries() returns CovidEntry[] {
    lock {
        CovidEntry[] entriesArray = from CovidEntry entry in covidEntriesTable select entry;
        return entriesArray.cloneReadOnly();
    }
}

public isolated function getEntry(string isoCode) returns CovidEntry? {
    lock {
        CovidEntry[] entries = from CovidEntry entry in covidEntriesTable where entry.isoCode == isoCode select entry;
        if entries.length() > 0 {
            return entries[0].cloneReadOnly();
        }
    }
    return;
}

public isolated function addEntry(CovidEntry entry) {
    lock {
        covidEntriesTable.add(entry.cloneReadOnly());
    }
}
