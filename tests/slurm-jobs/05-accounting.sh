#!/bin/bash
# Show accounting records for the last day, incl. GPU TRES usage.
sacct -a -S now-1days -X \
  -o JobID,User,Account,Partition,QOS,AllocTRES%40,Elapsed,State
sreport cluster AccountUtilizationByUser start="$(date -d yesterday +%F)" -t hours
