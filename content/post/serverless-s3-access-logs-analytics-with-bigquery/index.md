---
title: 'Serverless S3 Access Logs Analytics using BigQuery'
subtitle: 'Configuring a Serverless and full-managed system to analyze S3 access logs using BigQuery.'
summary: 'Configuring a Serverless and full-managed system to analyze S3 access logs using BigQuery.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
- Analytics
date: "2020-05-10T00:00:00Z"
lastmod: "2020-05-10T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./man_binoculars.jpg" title="Multi-cloud Data Analytics">}}

Do you use BigQuery? Are you interested in knowing how to integrate data from different cloud providers into BigQuery? In this blogpost, we will implement a **serverless** and **fully managed** system to make available S3 access logs into BigQuery to easily integrate them with other data sources and reporting systems. To achieve this we will see how to set up AWS S3 access logs delivery and configure Google [Data Transfer Service](https://cloud.google.com/storage-transfer/docs/create-manage-transfer-console#amazon-s3) in order to schedule fully managed S3 to Cloud Storage transfers.We will also use [BigQuery external table](https://cloud.google.com/bigquery/external-table-definition) to read data directly from Google Cloud Storage to access always to the most recent data without keeping reloading data into BigQuery. Finally, we will leverage [persistent UDFs](https://cloud.google.com/bigquery/docs/reference/standard-sql/user-defined-functions#temporary-udf-syntax) to parse the logs into tabular format on the fly.

## Set up S3 access logging
AWS allows you to export [S3 access logs](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerLogs.html), which can be used to monitor user access and build business metrics. Although, you can export logs for a specific bucket into itself, this might cause extra logs to get generated. In our scenario we use a different bucket to collect and store the access logs of many other buckets. Also, S3 access logs can be exported only to a bucket in the same region for the monitored one. So we will need to create a different bucket for each region where we have buckets that we want to monitor. In this scenario, we will work in the "eu-west-1" region. Let’s create a bucket to collect and store the access logs.

```bash
aws s3api create-bucket --bucket MY_BUCKET_EU-WEST-1 --region eu-west-1
```

Now we need to set up S3 access logs delivery. First we grant the AWS LogDelivery group the relevant permissions to our destination bucket:
```bash
aws s3api put-bucket-acl --bucket MY_BUCKET_EU-WEST-1 --grand-write URI=http://acs.amazonaws.com/groups/s3/LogDelivery --grant-read-acp URI=http://acs.amazonaws.com/groups/s3/LogDelivery
```

Then we define the logging configuration locally in a JSON file:
```json
{
  "LoggingEnabled": {
    "TargetBucket": "MY_BUCKET_EU-WEST-1",
    "TargetPrefix": "BUCKET_TO_LOG/",
  }
}
```

`TargetBucket` is the bucket where the logs will be delivered. You can provide a prefix for the logs using `TargetPrefix` (optional), we use it to separate the logs of different buckets but you could use a different logic. Now we need to enable logging:
```bash
aws s3api put-bucket-logging --bucket BUCKET_TO_LOG --bucket-logging-status file://logging.json
```

It’s worthy to remember that logs are delivered on a [best effort basis](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerLogs.html#LogDeliveryBestEffort), usually most log records are delivered within a few hours of the time they are recorded, but can be more frequently.

## Transfer logs to Google cloud Platform
In our scenario, we will transfer the data first into Cloud Storage using the [Data Transfer](https://cloud.google.com/storage-transfer/docs/create-manage-transfer-console#amazon-s3) service and then using [BigQuery external table](https://cloud.google.com/bigquery/external-table-definition) to run queries on them. Another possible solution would be to use [S3 to BigQuery](https://cloud.google.com/bigquery-transfer/docs/s3-transfer) data transfer service to directly transfer the data into BigQuery.
The Data Transfer service is fully managed, so you just need to configure it and you won’t need to provision and monitor any infrastructure. Transfers are scheduled to run every 24 hours, if you need a different interval you will have to implement the data transfer yourself instead of using this service. Before setting up the transfer we need a destination bucket on Cloud Storage. Let’s create a multi-regional bucket in Europe.
```bash
gsutil mb -l EU gs://MY_AWS_S3_ACCESS_LOGS_MIRROR/
```

To set up the transfer service, log into your cloud console to find *Data Transfer* under the *Storage* section. Now click on "Create a transfer job" and follow the steps below:
As a source we select "Amazon S3 bucket and include the bucket name we want to read from, in our example "MY-S3-ACCESS-LOGS-EU-WEST-1". We need to provide AWS authentication Access key ID and Secret access key that have the permission to read the bucket.
As the destination, we put the bucket we just created MY_AWS_S3_ACCESS_LOGS_MIRROR and leave all the other options un-ticked.
We select to run daily at a specific time.
Click on Create.

For more detailed information refer to the [official documentation](https://cloud.google.com/storage-transfer/docs/create-manage-transfer-console#amazon-s3).

We still need to be able to access the data in BigQuery to do our analytics and build reporting dashboards with Data Studio. Unfortunately, AWS S3 log entries are not in JSON or CSV-like format but they use their [own](https://docs.aws.amazon.com/AmazonS3/latest/dev/LogFormat.html). For this reason, BigQuery cannot automatically load it into a table with the desired schema. To have the logs parsed as we desire we will use a persistent UDF but first we need to make the log entries "available" to BigQuery. To do so, we define an external table that reads data from our mirror bucket in Cloud Storage and we have to configure it as the files use newline as field separator. As a result, we want a table where each row contains an entire log entry, we choose the newline character as field separator because we do not expect to have any of them in our log entries. This will result in a table with a single column.
To create our source table we can use the cloud console:
Select the dataset you want to create your table in and click create table.
In the table creation menu, select as source "Google Cloud Storage", CSV as format, and add the prefix of the data that you want to be the sources of the table (remember that you can use wildcard to say to BigQuery to select all the files within the prefix).
Choose your table name (in this example we will use "s3_raw_logs_external") and because we do not want to actually load the data, we need to select "External table" in "Table type".
In the schema section add a single column called "text" of type STRING.
Click on "Advanced options" and set the field delimiter to be "Custom" and insert s character that should never be present (e.g. "§"). You can leave the other options with their default values and click "create".

Now we have a table into BigQuery where the source data is in Cloud Storage, this means that every query reading from this table will always acces all the data present in the bucket at that time. Note that this setup might start having degraded performances for very large logs datasets.

## Transform raw logs into tabular format
As we said above , AWS S3 log entries are not in JSON or CSV-like format but they use their own format, so we need to parse them ourselves . We can easily do this directly in BigQuery using a persistent UDF. I wrote a Javascript UDF to parse most of the log entry parts into an object. Note that we use "\\" instead of "\" because we need to escape when defining the function.


```javascript
CREATE OR REPLACE FUNCTION `PROJECT_ID.DATASET_ID.s3_log_parser`(text STRING)
RETURNS STRUCT<bucket_owner STRING, bucket STRING, timestamp STRING, remote_ip STRING, requester STRING, request_id STRING, operation STRING, key STRING, request_uri STRING, http_status INT64, error_code STRING, bytes_sent INT64, object_size INT64, total_time INT64, turn_around_time INT64, referrer STRING, user_agent STRING, version_id STRING, host_id STRING, _error_message STRING, _s3_log_line STRING>
LANGUAGE js
AS """
/*
This regex follows the logformat specs at https://docs.aws.amazon.com/AmazonS3/latest/dev/LogFormat.html
Note that we need to use '\' instead of '' because BigQuery escaping rules and we also need to escape ‘\’ using ‘\\’. The function will be saved with a single ‘\’ but will need to be saved using ‘\\’ instead.
*/
var ACCESS_LOG_REGEXP = /(?:([a-z0-9]+)|-) (?:-|([\\w\\.\\-_]+)) (?:(\\[[^\\]]+\\])|-) (?:([\\d\\.]+)|-) (?:-|([\\w:\\/\\-_]+)) (?:([\\w.-_]+)|-) (?:([\\w\\.]+)|-) (?:-|([\\w0-9\\.\\-_\\/%\\*\\?\\[\\]]+)) (?:"-"|"([^"]+)"|-) (?:(\\d+)|-) (?:([\\w]+)|-) (?:(\\d+)|-) (?:(\\d+)|-) (?:(\\d+)|-) (?:(\\d+)|-) (?:"-"|"([^"]+)"|-) (?:"-"|"([^"]+)"|-) (?:([\\w]+)|-) (?:([\\w\\+\\/=]+)|-) (?:([\\w]+)|-) (?:([\\w-]+)|-) (?:([\\w-]+)|-) (?:([\\w-\\.]+)|-) (?:([\\w\\.]+)|-)/i;
this._s3_log_line = text;
var matches = null;
// Catch error during regex
try {
  matches = text.match(ACCESS_LOG_REGEXP);
} catch(err) {
  this._error_message = err.message;
  this._s3_log_line = text;
  return this;
}

// Parse first tier fields, we want this field to be all present or get a failure with an error message.
try {
  this.bucket_owner = matches[1];
  this.bucket = matches[2];
  this.timestamp = matches[3];
  this.remote_ip = matches[4];
  this.requester = matches[5];
  this.request_id = matches[6];
  this.operation = matches[7];
  this.key = matches[8];
  this.request_uri = matches[9];
  this.http_status = matches[10];
  this.error_code = matches[11];
  this.bytes_sent = matches[12];
  this.object_size = matches[13];
  this.total_time = matches[14];
  this.turn_around_time = matches[15];
} catch(err) {
  this._error_message = err.message;
  this._s3_log_line = text;
  this._parse_result = JSON.stringify(matches);
  return this;
}

// Parse additional fields
try {
  this.referrer = matches[16];
  this.user_agent = matches[17];
  this.version_id = matches[18];
  this.host_id = matches[19];
  } catch(err) {
  this._error_message = err.message;
  this._s3_log_line = text;
  return this;
}
return this;
""";
```
Here you can find the [GitHub gist](https://gist.github.com/alepuccetti/544863656931199027c894b02497c2eb).

You can copy and paste the code above into the BigQuery UI to create the **s3_log_parser** as a persistent UDF, just replace `PROJECT_ID` and `DATASET_ID` with valid values for your environment.

Now we have easy access to the data and the logic to transform it into tabular format, the following query will parse all the logs entry into the column defined in the UDF.
```sql
select
  s3_log.* except(timestamp, _error_message, _s3_log_line),
  parse_timestamp("[%d/%b/%Y:%H:%M:%S %z]", s3_log.timestamp) as timestamp
from (
  select
    `PROJECT_ID.DATASET_ID.s3_log_parser`(text) as s3_log
  from `PROJECT_ID.DATASET_ID.s3_raw_logs_external`
)
;
```
Let’s copy and paste this query into the BigQuery UI and run it. If you have already data into the Cloud Storage bucket you will see the logs parsed out. Now click on "Save view", choose a destination dataset and a name for the view (e.g. s3_logs_parsed). In this way, we can use the view as a source for our analytics reporting dashboards instead of always writing the query itself. Now try the following query, it should show the same results of the previous one.

```sql
Select
*
from PROJECT_ID.DATASET_ID.s3_logs_parsed
```

Now you have a serverless, fully-managed system to analyse your AWS S3 access logs into BigQuery using SQL and play with Google [Datastudio](https://datastudio.google.com/) to build and share reporting dashboards.

