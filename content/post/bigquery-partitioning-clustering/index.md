---
title: 'BigQuery Partitioning & Clustering'
subtitle: 'Improving performance at a fraction of the cost.'
summary: 'Improving performance at a fraction of the cost.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
date: "2020-01-21T00:00:00Z"
lastmod: "2020-01-21T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./shipping_containers.jpg" title="Shipping Containers">}}

In this blogpost, I will explain what partitioning and clustering features in BigQuery are and
how to supercharge your query performance and reduce query costs.

# Partitioning
Partitioning a table can make your queries run faster while spending less.
Until December 2019, BigQuery supported table partitioning only using **date data type**.
Now, you can do it on integer ranges too.
If you want to know more about partitioning your tables this way,
check out this [great blogpost](https://medium.com/google-cloud/partition-on-any-field-with-bigquery-840f8aa1aaab) by Guillaume Blaquiere.

Here, I will focus on date type partitioning.
You can partition your data using 2 main strategies:
on the one hand you can use a table column, and on the other, you can use the data time of ingestion.

This approach is particularly useful when you have very large datasets that go back in time for many years.
In fact, if you want to run analytics only for specific time periods, partitioning your table by time allows BigQuery
to read and process only the rows of that particular time span.
Thus, your queries will run faster and, because they are reading less data, they will also cost less.

Creating a partitioned table is an easy task.
At the time of table creation, you can specify which column is going to be used for partitioning,
otherwise, you can set up the partitioning on [ingestion time](https://cloud.google.com/bigquery/docs/creating-partitioned-tables).
Since you can query this table in the same exact way of those that are not partitioned, you won't have to change a line of your existing queries.

{{< gist alepuccetti 859d196d00588efcfb08724218cfabaf "query_partition.sql">}}

Assuming that "**sampling_date**" is the partitioning column,
now BigQuery can use the specified values in the "where clause" to read only data that belong to the right partitions.

#### Bonus nugget

You can use **partition decorators** to update, delete, and overwrite entire single partitions as in:

```bash
# overwrite single partition loading from file
bq load —-replace \
  project_id:dataset_name.table_name$20190805 \
  gs://my_input_bucket/data/from/20190805/* ./schema.json
```

And

```bash
# overwrite single partition from query results
bq query —- replace --use_legacy_sql=false \
  —-destination_table project_id:dataset.table$20190805 \
  'select * from project_id:dataset.another_table'
```

In the cases above, both the loaded data and the query results have to belong to the referenced partition, otherwise the job will fail.

# Clustering
Clustering is another way of organizing data which stores one next to the other all those rows that share similar values in the chosen clustering columns.
This process increases the query efficiency and performances.
Note that BigQuery supports this feature only on partitioned tables.

BigQuery can leverage clustered tables to read only data relevant to the query, so it becomes faster and cheaper.

At the table creation time, you can provide up to 4 clustering columns in a comma-separated list e.g. "**wiki**", "**title**".
You should also keep in mind that their order is of paramount importance but we will see this in a moment.

In this section we will use "_wikipedia_v3_" form [Felipe Hoffa](https://twitter.com/felipehoffa)'s public dataset,
which contains yearly tables of Wikipedia page views.
These are partitioned by the "**datehour**" column and clustered on "**wiki**" and "**title**" columns.
A single row may look like this:

```csv
datehour,                    language,     title,   views
2019–08–10 03:00:00 UTC,     en,           Pizza,   106
...
```

The following query counts, broken-down per year, all the page views for the Italian wiki from 2015–01–01.

{{< gist alepuccetti 859d196d00588efcfb08724218cfabaf "IT_query_cluster.sql">}}

If you write this query in BigQuery UI, it will estimate a data scanning of 4.5 TB.
However, if you actually run it, the final scanned data will be of just 160 GB.

*How is this possible?*

When BigQuery reads only read rows belonging to the cluster that contains the data for the Italian wiki while discarding everything else.

*Why is the columns order so important in clustering?*

It is important because BigQuery will organize the data hierarchically according to the column order that is specified when the table is created.

Let's use the following example:

{{< gist alepuccetti 859d196d00588efcfb08724218cfabaf "pizza_query_cluster.sql">}}

This query needs to access all the "wiki" clusters and then it can use the "title" value to skip the not matching clusters.
This results in scanning a lot more data than if the clustering columns were in the opposite order "**title**", "**wiki**".
At the time of writing, the query above estimated a scanning cost of 1.4 TB but it actually scanned only 875.6 GB of data.
Let's now invert the clustering columns order putting first "**title**" and second "**wiki**", you can do so using the following command:

```bash
bq query --allow_large_results --nouse_legacy_sql \
  --destination_table my_project_id:dataset_us.wikipedia_2019 \
  --time_partitioning_field datehour \
  --clustering_fields=title,wiki \
'select * from `fh-bigquery.wikipedia_v3.pageviews_2019`'
```

Running the "Pizza" query on our new table "**my_project_id:dataset_us.wikipedia_2019**" should be much cheaper.
In fact, while the estimation was still of 1.4 TB, the actual data read was just of 26.3 GB, that is 33 times less.

As final test let's try filtering on the "**wiki**" column:

{{< gist alepuccetti 859d196d00588efcfb08724218cfabaf "IT_query_cluster_after_re_cluster.sql">}}

The data read estimation is always the same but now the actually data read jumped to 1.4 TB (the entire table)
whereas, in the first example, the actually data read was just of 160 GB.

**Note**: Since BigQuery uses a columnar store, "**title is not null**" ensures that we refer always to the same number of columns in every query.
Otherwise, the data read from the last query is lower because we refer to fewer columns.

It is evident that choosing the right clustering columns and their order makes a great difference.
You should plan it accordingly to your workloads.

Remember, always **partition** and **cluster** your tables!
It is free, it does not need to change any of your queries and it will make them cheaper and faster.
