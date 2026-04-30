Extract raw CSV logs
→ Filter malformed records
→ Parse request field into method / endpoint / protocol
→ Derive date and hour from timestamp
→ Categorize endpoint type (html/image/download/cgi/other)
→ Group by hour
→ Aggregate:
   total_requests
   total_bytes
   avg_bytes
   total_get_requests
   total_post_requests
   total_head_requests
   total_other_method_requests
   html_requests
   image_requests
   download_requests
   cgi_requests
   other_endpoint_requests
   status_2xx_count
   status_4xx_count
   status_5xx_count
→ Load hourly_summary.csv
