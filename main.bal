import ballerina/graphql;

import covid19.datasource as ds;

service /covid19 on new graphql:Listener(9000) {
    resource function get allData() returns CovidData[] {
        ds:CovidEntry[] covidEntries = ds:getAllEntries();
        return covidEntries.map(covidEntry => new CovidData(covidEntry));
    }

    resource function get filterData(string isoCode) returns CovidData? {
        ds:CovidEntry? covidEntry = ds:getEntry(isoCode);
        if covidEntry is ds:CovidEntry {
            return new(covidEntry);
        }
        return;
    }

    remote function addEntry(ds:CovidEntry entry) returns CovidData {
        ds:addEntry(entry);
        return new CovidData(entry);
    }
}
