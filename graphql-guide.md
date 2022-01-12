# Tutorial: Developing a GraphQL API with Ballerina

This simple guide helps you understand the basics of Ballerina constructs which allow you to write GraphQL APIs.

Due to the batteries included nature of the Ballerina language there is no need to add any third party libraries to 
implement the GraphQL API. The Ballerina standard library itself is adequate. In this API you will be writing a simple 
GraphQL service to serve dummy dataset related to Covid-19.

To get the best out of the guide, it is better to have some sense about Ballerina language capabilities such as 
queries, isolation, etc.

This tutorial includes the following steps:

1. Design the GraphQL endpoint
2. Create the Covid-19 dataset
3. Write the GraphQL service to:
   - Get all the Covid-19 data
   - Add Covid-19 data
   - Filter Covid-19 data using the `isoCode` 

## Prerequisites

- Ballerina SwanLake installation (To download Ballerina, visit [Download Ballerina](https://ballerina.io/downloads/))
- A tool to edit the code. (VSCode with Ballerina plugin is recommended. To download,
  visit [Ballerina VSCode Plugin](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina))
- A command terminal.

## Design the GraphQL endpoint
Usually, a GraphQL endpoint is defined using a GraphQL schema. Some languages require the GraphQL schema to create 
a GraphQL service (schema-first approach), while some languages does not need the schema to create the service. 
(code-first approach). Ballerina GraphQL package uses the latter.
Therefore, we do not need the schema file to create our service. But for the sake of the design, let's look at the 
GraphQL schema.

```graphql
type Query {
    allData: [CovidData!]!
    filterData: CovidData
    addData(entry: CovidEntry!): CovidData!
}

scalar Decimal

type CovidData {
    isoCode: String!
    country: String!
    recovered: Decimal
    cases: Decimal
    active: Decimal
    deaths: Decimal
}

input CovidEntry {
    isoCode: String!
    country: String!
    recovered: Decimal
    cases: Decimal
    active: Decimal
    deaths: Decimal
}
```

> Note: The `Decimal` type used here is coming from the `decimal` type in Ballerina language. We are using this type 
> to store the case counts. More about this later.

Now that we have the design, we can create the project.

## Create a Ballerina Project

1. Open a terminal and move to the directory where you want to create the Ballerina project.

   On Linux or Mac:
    ```shell
    cd your/parent/directory/path
    ```

   On Windows:
    ```windows
    cd your\parent\directory\path
    ```
2. Using the `bal` command, create a new Ballerina project.
    ```shell
    bal new covid19_graphql_server
   ```

This will create a new Ballerina project inside a directory named `covid19_graphql_server`.

## Create Data for the Project

Before writing the GraphQL service, we are going to create a data source for out project. This will mimic a database
where we store the data for our service. Use the following command to create a new module inside the Ballerina project.

```shell
bal add datasource
```

This will create a new directory named `modules/datasource`, which will be the Ballerina module acting as the data
source of the GraphQL service.

Now, let's add the data needed for the GraphQL service inside this module.

First, we have to define our data types. We can use Ballerina records for this. Let's first define a Ballerina record to
store an entry in the database. Although the Covid-19 database has many fields, for this guide we only use the `isoCode`
, `continent`, `location`, `date`, `totalCases`, and `newCases`. Let's create a record with these fields.

To do so, let's create a file `types.bal` inside the `modules/datasource` directory and add the following record
definition there.

```ballerina
public type CovidEntry record {|
    readonly string isoCode;
    string country;
    decimal cases?;
    decimal deaths?;
    decimal recovered?;
    decimal active?;
|};
```

Now we need a table to store the sample data. For this tutorial, we are going to use an in-memory table with just 
three entries. Let's define the table inside the auto-created `datasource.bal` file as follows:

```ballerina
isolated table<CovidEntry> key(isoCode) covidEntriesTable = table [
    {isoCode: "AFG", country: "Afghanistan", cases: 10000, deaths: 500, recovered: 1500, active: 8000},
    {isoCode: "SL", country: "Sri Lanka", cases: 20000, deaths: 1000, recovered: 4000, active: 15000},
    {isoCode: "US", country: "United States", cases: 40000, deaths: 5000, recovered: 15000, active: 20000},
]
```

Then we can define functions to mock the database operations. Although we use an in-memory table, we can use any 
data source and use the same functions to access them, so that the GraphQL service will not have any impact when the 
datasource is changed.

First, the following function will return all the entries from the table.

```ballerina
public isolated function getAllEntries() returns CovidEntry[] {
    lock {
        CovidEntry[] entriesArray = from CovidEntry entry in covidEntriesTable select entry;
        return entriesArray.cloneReadOnly();
    }
}
```

Then another function to get an entry from the `isoCode`. This will return the `CovidEntry` record if the provided
`isoCode` is found in the table, `nil` otherwise.

```ballerina
public isolated function getEntry(string isoCode) returns CovidEntry? {
    lock {
        CovidEntry[] entries = from CovidEntry entry in covidEntriesTable where entry.isoCode == isoCode select entry;
        if entries.length() > 0 {
            return entries[0].cloneReadOnly();
        }
    }
    return;
}
```

Let's now define another function to add an entry to the table.

```ballerina
public isolated function addEntry(CovidEntry entry) {
    lock {
        covidEntriesTable.add(entry.cloneReadOnly());
    }
}
```

> Note: A `lock` is used to access the table to make the operations concurrent-safe.

Now our data source is completed. Let's move on to writing the GraphQL service now.

## Write Ballerina GraphQL service
As per our schema (as mentioned in the [design section])




[design section]: #design-the-graphql-endpoint "Design the GraphQL Endpoint"
