#/bin/bash
curl -X PUT 'https://api.newrelic.com/v2/alert_policies/235437.json' -H 'X-Api-Key:758ff2178c4b4e490822cc8b119e7c2174695a2d9eb155e' -i -H 'Content-Type: application/json' -d '{"alert_policy": {"enabled": "true"}}' 
