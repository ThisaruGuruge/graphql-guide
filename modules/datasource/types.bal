public type CovidEntry record {|
    readonly string isoCode;
    string country;
    decimal cases?;
    decimal deaths?;
    decimal recovered?;
    decimal active?;
|};
