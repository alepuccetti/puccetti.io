---
title: 'BigQuery Wildcards'
subtitle: 'Managing massive datasets using wildcards.'
summary: 'Managing massive datasets using wildcards.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
date: "2020-01-06T00:00:00Z"
lastmod: "2020-01-06T00:00:00Z"
featured: false
draft: false
---

BigQuery supports the "\*_"_ wildcard to reference multiple tables or files.
You can leverage this feature to load, extract, and query data across multiple sources, destinations, and tables.
Let's see what you can do with wildcards with some examples.

The first thing is definitely loading the data into BigQuery.
If you deal with a very large amount of data you will have, most likely,
tens of thousands of files coming from a data pipelines that you want to load into BigQuery.
Using wildcards, you can easily load data from different files into a single table.

```bash
bq load project_id:dataset_name.table_name gs://my_data/input/prefix/* ./schema.json
```

Also, this is not limited to only one prefix but you can specify multiple ones for example:

```bash
bq load project_id:dataset_name.table_name gs://my_data/input/prefix_1/* gs://my_data/input/prefix_5/* gs://my_data/input/prefix_25/* ./schema.json
```

The command above will load all the files matching all the prefixes into the specified table.

Wildcards can be used in the other direction too.
Namely, they can be used to export data from BigQuery to GCS.
This is very useful especially because BigQuery limits exports to a single file only to tables smaller than 1GB.

```bash
bq extract project_id:dataset_name.table_name gs://my_data/extract/prefix/file_prefix_*.json
```

The previous command will result in multiple files exported into the _"my_data"_ bucket within the prefix _"extract/prefix/"_ and all file names will be:

```bash
file_prefix_000000000000.json
file_prefix_000000000001.json
file_prefix_000000000002.json
…
file_prefix_000000003792.json
file_prefix_000000003793.json
```

The other very useful use of wildcards is evident in queries.
In fact, you can reference multiple tables in a single query by using _"_"\* to match all the table into the dataset with the same prefix.
For example, consider you have a collection of tables like:

```bash
my_dataset
├── events_GB
...
├── events_IT
...
├── events_US
...
```

The following query will return the count per day per country of events of type _"submit"_ in our dataset.

```sql
select
  _table_suffix as country,
  day,
  count(*)
from events_*
where type = "submit"
group by 1,2
```

You can also filter out matched tables using _"\_table_suffix"_ in the where clause.
For example, if you are only interested in Germany, France, and Japan just run the following:

```sql
select
  _table_suffix as country,
  day,
  count(*)
from events_*
where type = "submit"
and _table_suffix in ("DE", "FR", "JP")
group by 1,2
```

What I personally like the most of using wildcards is that it enables me to design better, simpler,
and more generic analytics queries as well as ETL jobs.
The aim of this post was to help you improve your code quality and your productivity.

If you believe you learnt something new or if you liked the post please Clap.
Happy query with BigQuery!!!
