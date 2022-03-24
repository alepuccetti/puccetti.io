---
title: 'Saving Bank with Cloud Workflows'
subtitle: 'Optimize orchestration with Cloud Workflows.'
summary: 'Optimize orchestration with Cloud Workflows.'
authors:
- admin
tags:
- Automation
categories:
- Data Engineering
date: "2022-03-24T00:00:00Z"
lastmod: "2022-03-24T00:00:00Z"
featured: false
draft: false
---

“Workflows is a fully-managed orchestration platform that executes services in an order that you define”.

{{< figure src="./workflow_wood.jpeg" title="Workflow">}}

In this blogpost, I will show you how I was able to increase performance, reduce cost, and improve code quality by migrating our ETL orchestration from Cloud Composer to Cloud workflows.

## The Journey

I am a die-hard fan of managed and serverless services.
That’s because they allow me to spend more time on developing interesting projects instead of maintaining infrastructure (boring!).

Few years ago, at Huq Industries, we were redesigning our infrastructure by using BigQuery and Dataflow for our analytics and batch processing.
During this process, we also needed to strengthen the orchestration and scheduling of our ETLs and data delivery processes.
After evaluating different solutions, we decided to implement our orchestration with Cloud Composer (fully managed Apache Airflow solution from Google Cloud).
I knew from the beginning that Airflow would have been an overkill for our needs.
In particular because we don’t process data locally on the Airflow cluster but only via external services like Dataflow and BigQuery.
However, I wanted to have the peace of mind of a fully-managed solution and an easy-to-use system.

Although Cloud Composer has been great for day-to-day operation, it also caused some pain along the way, especially when I needed to re-run data pipelines spanning across a few years (see my previous blog post regarding Airflow short-living tasks).
Lastly, having a cluster always up and running when you use it only a few hours a day is quite the waste of resources, but it was necessary for the business operations.

## The Dawn of Serverless Orchestration

When Google announced Cloud Workflows, I was very excited because I saw from the start that it would have been perfect for us.
So, I decided to take Cloud Workflows out for a spin.

I started migrating the data pipelines and data export, and, to my pleasant surprise, the migration was incredibly fast and the final result was a much **better code** base.
One could  describe it as “directly to the point”.
This new implementation drastically improved code readability, maintainability, and reusability.
The second benefit was the ludicrous increase in end-to-end performance.
In fact, before Cloud Workflows, a daily task needed about 30 minutes to complete, now it needs only 4 minutes (\~8X faster).

This speed improvement is even greater when running full history exports, while before it took almost a month, now it takes less than a working day (**\~40X**).
I want to highlight that I did not do any optimization to the external ETL jobs, so the performance improvements can all be attributed to Cloud Workflows.

The main reason for this incredible improvement is that the external tasks are quick compared to the scheduling and instantiating time of Airflow tasks.
Cloud Workflows **remove completely this non-processing time overhead**, so now the pipelines only last the time needed by the external service to complete.
A little drawback is that Cloud Workflows does not provide scheduling as a native feature like Airflow. On the other hand, it is incredibly simple to schedule your Workflows using Cloud Scheduler.

The last, but definitely not least, advantage is the cost saving.
To be able to meet the clients' needs, we had to keep the Airflow cluster running 24/7 (even if tasks had about 3 hours of runtime per day) costing about 900\$/month.
With Cloud workflows, per step pricing model you just pay for how many “actions” you execute.
For this reason, the **cost dropped by several orders of magnitude**. Running the daily tasks with Cloud workflows costs us 0.05\$ per day (1.5\$/month) which is a cost reduction of **600X**.
This makes the new system almost running for free.
The cost saving is staggering even for the full history re-running example, which boils down to just 70$.

## Conclusion

In conclusion, Cloud Workflows is the perfect match. It allows you to create simple and clear orchestration logic with amazing performance improvement and cost reduction.
At the moment of writing, Cloud Workflows is still a fairly new product in active development but it’s improving at a very high pace.
