---
title: 'BigQuery Geography Clustering'
subtitle: 'Improve your geospatial analytics performance in minutes.'
summary: 'Improve your geospatial analytics performance in minutes.'
authors:
- admin
tags:
- BigQuery
categories:
- Data Engineering
- Geospatial
date: "2020-01-30T00:00:00Z"
lastmod: "2020-01-30T00:00:00Z"
featured: false
draft: false
---

{{< figure src="./world-map-colored-countries.png" title="World Map">}}

The BigQuery team rolled out support for [geography type](https://cloud.google.com/bigquery/docs/gis-data) a while ago and
they have never stopped improving performances and [Geographic Information System functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/geography_functions) (GIS).
This allows users to run _complex geo-spatial analytics_ directly in BigQuery harnessing all its power, simplicity, and reliability.

Hold on your keyboard (or your screen if you are reading this on a mobile device).

**Now you can cluster tables using a geography column**. Say what!!!!

This is game changing for users working heavily with geodata.
By clustering your table on a geography column, BigQuery can reduce the amount of data that needs to read to serve the query.
This makes queries cheaper and run faster when filtering on clustering column.

Let's see the benefits of clustering table using geography column with an example.
We will use one of the great public datasets curated by [Felipe Hoffa](https://twitter.com/felipehoffa).
We will use the _weather_gsod_ specifically the two tables _all_ and _all_geoclustered_.

Let's say that we want the all-time minimum and maximum temperature within the Greater London area for each station.
Our query will look like this:

```sql
select
  name,
  min(temp) as min_temp,
  max(temp) as max_temp
from `fh-bigquery.weather_gsod.all`
where st_within(point_gis, st_geogfromtext('POLYGON((-0.5191087546253357 51.69057940987663,-0.5850267233753357 51.530249275252345,-0.5685472311878357 51.33504597185959,-0.19226549290658568 51.2285324250183,0.20049573756216432 51.271511154557565,0.3185987649059143 51.55074848767514,0.2856397805309143 51.64628942375177,0.04943372584341432 51.72461916884517,-0.5191087546253357 51.69057940987663))'))
group by 1
```

Results:

```csv
name                min_temp  max_temp
ST JAMES PARK       26.3      83.2
KENLEY AIRFIELD     18.0      82.8
HEATHROW            18.6      83.4
CITY                22.3      92.2
BLACKWALL           37.0      62.2
NORTHOLT            18.4      84.1
BIGGIN HILL         15.5      90.3
PURLEY OAKS         23.0      81.7
LEAVESDEN           22.3      89.1
LONDON WEA CENTER   20.0      85.2
KEW-IN-LONDON       23.3      82.4
```

This query reads **9.02GB** of data.
Now let's see how the same query perform on the clustered table:

```sql
select
  name,
  min(temp) as min_temp,
  max(temp) as max_temp
from `fh-bigquery.weather_gsod.all_geoclusterd`
where st_within(point_gis, st_geogfromtext('POLYGON((-0.5191087546253357 51.69057940987663,-0.5850267233753357 51.530249275252345,-0.5685472311878357 51.33504597185959,-0.19226549290658568 51.2285324250183,0.20049573756216432 51.271511154557565,0.3185987649059143 51.55074848767514,0.2856397805309143 51.64628942375177,0.04943372584341432 51.72461916884517,-0.5191087546253357 51.69057940987663))'))
group by 1
```

The result is obviously the same but, this time, BigQuery reads just **98.97MB** of the data!!!
So switching to the geo clustered table made this query almost **100 times** cheaper.
Do you want to try other locations and test the differences yourself? You can use Huq Industries [GisMap tool](https://gismap.huq.io) to quickly draw and export polygons in various formats.

{{< figure src="./huq_gismap_london_m25.jpeg" title="[Huq GisMap](http://gismap.huq.io/)">}}
