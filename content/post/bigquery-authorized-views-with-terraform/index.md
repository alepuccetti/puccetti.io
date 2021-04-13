---
title: 'BigQuery Authorized Views with Terraform'
subtitle: 'Define and manage BigQuery authorized views in Terraform.'
summary: 'Define and manage BigQuery authorized views in Terraform.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
- Automation
date: "2021-04-13T00:00:00Z"
lastmod: "2021-04-13T00:00:00Z"
featured: false
draft: false
---


{{< figure src="./bq_tf.png" title="" alt="BigQuery + Terraform" >}}

In one of my previous blog posts, we have seen how, at [Huq Industries](https://huq.io), we used authorised views to reduce costs, complexity, and delivery time.
You can read more about it [here]({{< relref "/post/bigquery-real-time-data-delivery-at-scale/index.md" >}}).
In this post, we will see how to implement authorised views in production and managing them as code.
This solution enables us to easily manage 100s of clients, each one with unique data requirements.
To better manage and automate our workflow, we source control and review all our Google Cloud Platform data infrastructure using GitHub and Terraform Cloud.
This enabled us to easily communicate, track, and maintain infrastructure changes.
Let’s see how to define views and authorize them in the needed datasets. 
First, we would need a **dataset** in the client project to contain a view, then we would need the **view** itself, and finally the **authorization**.

Define the **dataset**
{{< gist alepuccetti 87a74e9469a612271d9adda8676eef50 "define_user_dataset.tf" >}}

Define the **view**
{{< gist alepuccetti 87a74e9469a612271d9adda8676eef50 "define_user_view.tf" >}}

Lastly, we have to **authorise** the view to access any needed dataset (in this example just one)
{{< gist alepuccetti 87a74e9469a612271d9adda8676eef50 "authorize_user_view.tf" >}}

After having generated and checked the plan you can apply it.
The view will then be created so that each user who has access to it can run queries without having direct access to the underlying tables.

To easily scale this to 100s of clients, we can write a terraform module that implements the last 2 steps and invoke it for each client we need to provision with just different variables such as: `client_project_id`, `client_dataset_name`, `view_name`, `view_query`, and the list of `project_id`, `datase_id`, to autorise.

One of the nicest things of authorised views is that the authorisation works as a chain.
At Huq, we leverage this behaviour so that we just have to authorise the clients views to the dataset that directly accesses them.
We use authorised views almost everywhere so that if one of these views are used by some other views, the end user does not need extra authorisation.

### WARNING
If you also manage datasets access via other terraform resources such as: `bigquery_dataset_iam_policy`, `bigquery_dataset_iam_binding`, or `bigquery_dataset_iam_member`. 
They will fight over what the policy should be with `google_bigquery_dataset_access`.
In fact, using any of the `google_bigquery_dataset_*` resources will result in removing any authorised views from that dataset previously configured via `google_bigquery_dataset_access`.

You can read more about this in the terraform [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_access).

Follow or contact me on Twitter for more stories about data, infrastructure, and automation.
