# Tutorial: Developing a GraphQL API with Ballerina

This simple guide helps you understand the basics of Ballerina constructs which allow you to write GraphQL APIs.

Due to the batteries included nature of the Ballerina language there is no need to add any third party libraries to
implement the GraphQL API. The Ballerina standard library itself is adequate. In this API you will be writing a simple
GraphQL service to serve dummy dataset related to Covid-19.

To get the best out of the guide, it is better to have some sense about Ballerina language capabilities such as queries,
isolation, etc.

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

Usually, a GraphQL endpoint is defined using a GraphQL schema. Some languages require the GraphQL schema to create a
GraphQL service (schema-first approach), while some languages does not need the schema to create the service.
(code-first approach). Ballerina GraphQL package uses the latter. Therefore, we do not need the schema file to create
our service. But for the sake of the design, let's look at the GraphQL schema.

```graphql
type Query {
    allData: [CovidData!]!
    filterData(isoCode: String!): CovidData
}

type Mutation {
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
    bal new covid19
   ```

This will create a new Ballerina project inside a directory named `covid19`.

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

Now we need a table to store the sample data. For this tutorial, we are going to use an in-memory table with just three
entries. Let's define the table inside the auto-created `datasource.bal` file as follows:

```ballerina
isolated table<CovidEntry> key(isoCode) covidEntriesTable = table [
    {isoCode: "AFG", country: "Afghanistan", cases: 10000, deaths: 500, recovered: 1500, active: 8000},
    {isoCode: "SL", country: "Sri Lanka", cases: 20000, deaths: 1000, recovered: 4000, active: 15000},
    {isoCode: "US", country: "United States", cases: 40000, deaths: 5000, recovered: 15000, active: 20000},
]
```

Then we can define functions to mock the database operations. Although we use an in-memory table, we can use any data
source and use the same functions to access them, so that the GraphQL service will not have any impact when the
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

## Write Ballerina service

As per our schema (as mentioned in the [design section]) we first have to define the `CovidData` object type. In
Ballerina GraphQL the preferred way to define output objects is to use service types.
> Note: Ballerina records can be used as output objects as well.

### Create GraphQL Object Types

Let's create a new file named `covid_data.bal` to define this service type. Following is the definition of the
`CovidData` object type.

```ballerina
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
```

Here, we are creating a `CovidData` service type using a `CovidEntry` record type. Then each resource function inside
this service type represents a field in the GraphQL object. The return type of the resource function is the type of the
field. Each resource function returns a field from its `CovidEntry` record.
> Note how the `decimal` type is returned from the resource functions. This will add a `Scalar`
type named `Decimal` to the GraphQL schema, which will be generated by the Ballerina GraphQL package.

### Writing the GraphQL service

Now that we have our main data type, we can write the GraphQL service. To do this, we can use the auto-generated
`covid19.bal` file.

First we have to import the GraphQL module, and then write a service attached to a GraphQL listener. In the following
code snippet, we first import the GraphQL package, and then define a service attaching a GraphQL listener.

```ballerina
import ballerina/graphql;

service /covid19 on new graphql:Listener(9000) {

}
```

In the above code snippet, the path of this service is defined as `/covid19`. If we want to host the service on the
root, we can remove the path as the following code snippet:

```ballerina
import ballerina/graphql;

service on new graphql:Listener(9000) {

}
```

When creating the `graphql:Listener` object we need to provide the port on which it is listening to. Alternatively, an
existing `http:Listener` object can also be used to initialize the `graphql:Listener` as below.

```ballerina
import ballerina/graphql;
import ballerina/http;

listener http:Listener httpListener = check new(9000);

service /covid19 on new graphql:Listener(httpListener) {

}
```

This is same as the first code snippet above, which will listen on the port `9000` and serve on `/covid19`.

Now we can create our service methods.

As per our schema, there are two fields in the `Query` type. To add fields to the root `Query` type, we have to use
resource methods. Each resource method inside the GraphQL service is mapped to a field in the root `Query` type.

Let's first create the `allData` field. This should return an array of `CovidData` type.

```ballerina
import ballerina/graphql;

import covid19.datasource as ds;

service /covid19 on new graphql:Listener(9000) {
    resource function get allData() returns CovidData[] {
        ds:CovidEntry[] covidEntries = ds:getAllEntries();
        return covidEntries.map(covidEntry => new CovidData(covidEntry));
    }
}
```

The resource method definition has the accessor `get`, which is used to identify the resource methods as a field of the
`Query` type. No other accessor is allowed. Then comes the name of the field. The return type is the type of the field.

If we look at the above resource method, we first retrieve the array of `CovidEntry` records from our datasource using
the previously created function `getAllEntries`. Then we use ballerina `map` function on the array to create a
`CovidData` instance for each record, and then return the array of `CovidData`.

Similarly, we can define another resource method to add the `filterData` field. Note that this field has an input
`isoCode` to filter the data.

```ballerina
resource function get filterData(string isoCode) returns CovidData? {
    ds:CovidEntry? covidEntry = ds:getEntry(isoCode);
    if covidEntry is ds:CovidEntry {
        return new(covidEntry);
    }
    return;
}
```

In the above resource method, we define the `filterData` field in the root `Query` type. Since this field has an 
input parameter `isoCode`, we have to add an input parameter to the resource method. Then using the previously 
defined `getEntry` function, we can filter the relevant entry.

> Note: In our schema, the type of the `filterData` is `CovidData`, which is nullable. Similarly, our resource 
> method can return nil value.

Now the `Query` type is completed. We now need to define the `Mutation` type. To define mutation type, we use 
`remote` methods. Similar to how each resource method is mapped to a field in the root `Query` type, each remote 
method in the Ballerina GraphQL service is mapped to a field in the root `Mutation` type.

Let's define a remote method to add an entry to our datasource:

```ballerina
remote function addEntry(ds:CovidEntry entry) returns CovidData {
    ds:addEntry(entry);
    return new CovidData(entry);
}
```

This method requires a `CovidEntry` record as the input. When a remote or resource method has a record type as an 
input, it will be mapped to a GraphQL input object type. This is the requirement as per the schema we have.

The complete code for the Ballerina GraphQL service is below:
```ballerina
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
```

That's it! We can run this service now to serve a GraphQL API to our datasource. To run execute the following command:

```shell
bal run
```

Now if we connect to this service using the GraphQL Playground tool, we can see the following generated schema. 

![Generated Schema](resources/images/schema-image.png)


[design section]: #design-the-graphql-endpoint "Design the GraphQL Endpoint"
