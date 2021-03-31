---
title: 'Real-Time data delivery at scale with BigQuery'
subtitle: 'Leveraging BigQuery authorized views for fun and profit to deliver real-time data delivery as scale.'
summary: 'Leveraging BigQuery authorized views for fun and profit to deliver real-time data delivery as scale.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
- Automation
date: "2021-03-31T00:00:00Z"
lastmod: "2021-03-31T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./data_delivery.jpeg" title="" alt="Data Delivery">}}


At [Huq Industries](https://huq.io), we collect and process 30 billions events a month from more than 8 million devices.
Every day, we enrich, slice, and then deliver data feeds in various forms to our clients mainly via BigQuery, GCS, or S3.
<br>In the past 2 years, we have seen our data ingestion growing 4x each year and we forecast the same for the next years to come.
Our already large data history and its steady and high grow rate pose several challenges from ingestion to storage, from processing to delivery and others.
<br>All these parts can be very critical.
However, in this specific post, we will focus on the processing and delivery.
We will see how we leveraged [BigQuery Authorized Views](https://cloud.google.com/bigquery/docs/authorized-views) to cut our storage and processing costs, to reduce our delivery time to zero and to streamline the whole system by removing many processes and dependencies.

## The issue
Many of our clients access our data directly using our self-served analytics offering via BigQuery sandboxed instances.
<br>At the very beginning, our system was creating and updating tables for each individual client in its own instances.
This choice was based on how the core processing system created and updated the master tables (one table per country updated daily).
This soon resulted  in a lot of duplicated data which, in turn, was increasing our costs with the data growth and the number of clients.
<br>Hence, we **needed** to find a different design before it would have become unsustainable.

## The solution: Authorized Views Everywhere
Now that we leveraged BigQuery clustering (see previous [blogpost]({{< relref "/post/bigquery-partitioning-clustering/index.md" >}})), instead of sharding data into different tables for each country, we were able to simplify part of the data processing and delivery system removing ETL jobs and dependencies.
This resulted in **cost reduction** for both processing and storage.
Last, but definitely not least, it removed the delay in delivery time from when the data is ready to when the data is available to the clients.

**What is an authorised view?**

An authorised view is a SQL view that was **authorised** to read tables in a specific dataset.
This means that users, who are allowed to access the view, do not need to get permission  to access the underlined tables.
It is the view itself that holds that permission and acts as a sort of middle-man.

**How is this useful for us?**

In our case, we were able to provide all our clients with a view that grants them access only to the data they are subscribing to.
Each view can be different and customized according to each client's needs but all of them use the same source tables.
Thus, removing a lot of duplicated data and updating processes.

--------------------------------------------------------------------------------

Now, let’s assume that we have 10s of clients who subscribed to different timeframes and/or countries to our data.
Additionally, some of them needed customization of the table schema.
As you can imagine, the ETL jobs and their scheduling become quite complicated and pricey. Clearly, this won’t be sustainable when scaling up to **100s** or **1000s** of clients.
<br>**Authorised views** enabled us to optimize this issue and we can now easily serve any number of clients with custom data requirements with very little overhead.
This can be done by simply creating a view and authorising it to the master dataset:

{{< gist alepuccetti d608ebaac5995eaf382074911012cacf "create_view.sql">}}

After we created this view and we granted users access to it, they still won’t be able to successfully run their queries.
In fact, if an user does not have access to the underlying tables (i.e. `table_a` and `table_b`) and he/she runs a query using this view, that will result in a permission error.
<br>However, by authorizing the view to access `dataset_a` and `dataset_b` that will enable users to successfully run their queries.
<br>This can easily be done in the BigQuery explorer. To get to the “authorised views” menu go to `source_project_id` &#10141; `dataset_a` &#10141; "Share Dataset" &#10141; "Authorised Views". Now, you can configure which views have access to this dataset using their `project_id`, `dataset_id`, and `view_id`. In our example: `client_project`, `dataset`, and  `view_name`. Repeat this for all the dataset that the view needs to access, in our example we have 2 datasets in 2 different projects.

--------------------------------------------------------------------------------

## **Bonus**: views using views

BigQuery, before running a query, resolves all the views and finds all the source tables and verifies that the user or, in our case, the view can read from all them.
Otherwise will return a permission error.
<br>What we saw so far works well if our views use tables. **What if our authorised view uses another view?** Would this solution still work as is? Does our view need to be authorised on all the dataset used by all the used views and their views etc.?

**The answer is no**, at least not directly.

Of course you could authorise the final view to access all of these tables but, as you can imagine, this will result in a lot of dependencies, repetitions, and complex definitions that will be a nightmare to maintain.

**How can we successfully use views in an authorised view?**

The answer is **authorised views**. More precisely, we can use authorised views in another authorised view because the “inner” view will be authorised to access the resources creating a chain of authorisation. In this way, we can just simply manage the authorisation of each single view.


Stay tuned for an implementation of this using Terraform in the coming blogposts.

--------------------------------------------------------------------------------

Follow or contact me on Twitter for more stories about data, infrastructure, and automation.

