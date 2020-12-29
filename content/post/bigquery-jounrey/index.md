---
title: 'A Journey Through Big Data Using Google BigQuery'
subtitle: 'From few millions events per day to hundreds of millions'
summary: ''
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
date: "2019-08-01T00:00:00Z"
lastmod: "2019-08-01T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./bigquery_logo.svg" title="BigQuery">}}

Back in the early days of Huq we were ingesting a just few millions records per day into our geo-behavioural insights platform.
Today that figure is in the hundreds of millions.
During the period where our traffic was ramping intensively,
we quickly realised that our single high-spec bare metal server setup was not going to be enough for our analytics needs.

After all, what good is building a valuable data asset if you can't get answers out?
We wanted to find a way to retrieve answers in seconds, not days, and so we set ourselves a mission:
find a solution that allows us to query and obtain answers to sometimes complex, often spatial,
queries across billions of records in minutes at most.
We wanted **great performance**, high **reliability**, to make use of our **SQL** skills.
And all that with minimum set-up, and **minimal DevOps** management overhead. _Moon on a stick? Definitely._

We tested different solutions but it quickly became clear that [BigQuery](https://cloud.google.com/bigquery) was a step
(often several steps) ahead of the myriad other solutions that we evaluated.
We found BigQuery to be: **effortless** to set up and use with virtually zero management and DevOps overhead.
It has with blazingly fast performance, flexibility and portability.
We can't remember the last time we had to carve out a subset of our data, build indices and otherwise optimise our queries. Load your data, buckle up and go.

Because it is **fully managed** you get a lot of great features out-of-the-box:
high availability, **serverless** computing, automatic backups, logging and auditing.

Moreover, BigQuery UI is a great tool that allowed the team to get up and running fast.
BigQuery's Standard SQL removes the need to learn a new language, or set up special DB client
(although you can use many different SQL clients to connect to BigQuery).
It also offers a rapidly expanding menu of GIS functions that in some ways are easier to work with than those found in PostGIS.
Last but not least, BigQuery offers a simple pricing model that makes it very easy to estimate cost for internal and external projects,
and to keep a firm handle on spend.

Google BigQuery has dramatically improved our access to analytics and the insights that arise from our dataset.
Even relatively simple queries that in our heavily-optimised bare-metal environment still ran for several hours, on BigQuery returns seconds.
BigQuery has helped us to improve the breadth and quality of our analytical offerings through speed, complexity and the ability to iterate.
We also now serve many of our clients using BigQuery — either alone or as a backend.
BigQuery makes it possible offer direct access to our datasets to in-house data science teams, or to power specialised dashboards according to customer needs.

For us, Google BigQuery has helped our business make a huge leap forward — and there's no going back from here.
Stay tuned for more technical follow-ups on our use of Google BigQuery.
