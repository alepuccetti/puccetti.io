---
title: 'Time Travel with BigQuery'
subtitle: 'How to use BigQuery superpowers to rewind time.'
summary: 'How to use BigQuery superpowers to rewind time.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
date: "2021-03-09T00:00:00Z"
lastmod: "2021-03-09T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./time_bending.jpeg" title="" alt="Time bending">}}

Who does not like time travel? We all saw it and were fascinated by it in many sci-fi movies, unfortunately science did not crack real-life time travel yet.

However, we can “data time-travel”. Thanks to the amazing BigQuery SQL feature “FOR SYSTEM_TIME AS OF”, we can time travel (up to 7 days in the past) to a specific timestamp (for detailed information about the syntax refer to the [official documentation](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#for_system_time_as_of)).

This feature is extremely easy to use. In fact, we can simply modify any query by adding the  clause above mentioned to the FROM clause. The following example returns all rows in  `table_a` from exactly 3 hours ago.

{{< gist alepuccetti 277fe07f200ccac33f98ae4217740fa5 "time_travel_query_interval.sql">}}

Or we can specify a precise point-in-time.

{{< gist alepuccetti 277fe07f200ccac33f98ae4217740fa5 "time_travel_query_point_in_time.sql">}}


## How is this useful?
Ok, it is nice to talk about time travel, but how is this useful in real-life?
In the current age of high data integration, data is inserted, deleted, and modified at a high rate. In highly integrated and streaming systems, it is often challenging to plan and perform backups that can be used to recover from processing errors. In BigQuery this can be done by just selecting rows from a specific point-in-time. This removes the need to materialize snapshots (for the past 7 days) and give us incredible granularity (timestamp precision).
The most obvious use-case is **data recovery**. We can easily recover a table state by creating a new one from a specific point-in-time.

{{< gist alepuccetti 277fe07f200ccac33f98ae4217740fa5 "recover_table_point_in_time.sql">}}

A more interesting and less obvious use-case could be to ensure **consistent analytics** results over time from a table that is modified with a high frequency or that  receives streaming inserts.
In this case, we could configure the SQL query to always return results from a specific timestamp during a specific time frame. We could build a caching system to do that or we could use “FOR SYSTEM_TIME AS OF” with a specific point-in-time to “force” queries to always return results from a past table state and just change the value when we want the results from a different time.

{{< gist alepuccetti 277fe07f200ccac33f98ae4217740fa5 "point_in_time_analytics.sql">}}

Or for a more dynamic solution

{{< gist alepuccetti 277fe07f200ccac33f98ae4217740fa5 "delayed_analytics.sql">}}

Follow or contact me on Twitter for more stories about data, infrastructure, and automation.
