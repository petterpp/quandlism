## 0.8.3

* Call resetState before drawing and setting scales on toggle.

## 0.8.2

* Add second fallback for recalculating extents to prevent flat lines.
* Reset y axis values when toggle event is triggered (legend click).

## 0.8.1

* attachData renamed to data
* Add support for options.
* Process options that are processable.
* Add callbacks to data and more events.

## 0.8.0

* Basic callback support for adjust action.
* yAxisMin and yAxisMax attributes to override calculated extent.
* Lines are attached and processed through a single function for DRYness.
* Old constructors nuked.

## 0.7.4

* Build file from 0.7.3 was not included in 0.7.3 release. This release simply is a proper build of 0.7.3.

## 0.7.3:

* Check for attributes.show. Don't operate on line visibility if it is not present.

## 0.7.2

* Call line::setup function when merging data to refresh the date value for line data points.
* attributes.show is used to activate columns, NOT disable. This allows frequency/tranformation to be changed on datasets and line visibility to be maintained.

## 0.7.1

* Add build files!!

## 0.7.0

* Simplify build. render and refresh functions now being called inside of update and render functions.
* updateData function added. attachData only called when chart is built for the first time.
* Remove column visibility logic. Column visibility is determined by attributes.show, which is an array of column indicies.
